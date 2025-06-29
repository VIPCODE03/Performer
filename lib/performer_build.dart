import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

//-----------------------------DATA STATE----------------------------------
/// Lưu trữ trạng thái dữ liệu chỉ đọc
/// Ví dụ:
/*class ExerciseState extends DataState {
  final List<Exercise> exercises;
  final bool isLoading;

  const ExerciseState(this.exercises, this.isLoading);

  ExerciseState copyWith({
    List<Exercise>? exercises,
    bool? isLoading,
  }) {
    return ExerciseState(
      exercises ?? this.exercises,
      isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [exercises, isLoading];
}*/
abstract class DataState extends Equatable {
  const DataState();
}

//-----------------------------ACTION-EVENT------------------------------------
/// Xử lý sự kiện tác động lên [DataState] làm thay đổi trạng thái
/// Mỗi loại đều tác động đến 1 trạng thái cụ thể.

/// Kết hợp chạy tích hợp các action lại với nhau
/// Ví dụ:
/*abstract class DetailSubjectAction extends ActionUnit<DetailSubjectState> {}

class LoadData extends DetailSubjectAction with ActionExecutor {
  final int subjectId;

  LoadData(this.subjectId);

  @override
  Stream<DetailSubjectState> execute(DetailSubjectState current) async* {
    DetailSubjectState currentState = current;

    final theoryStream = run<TheoryState>(
      LoadTheoryBySubjectId(subjectId),
      current.theoryState,
    );

    final exerciseStream = run<ExerciseState>(
      LoadExerciseBySubjectId(subjectId),
      current.exerciseState,
    );

    yield* StreamGroup.merge([
      theoryStream.map((stream) => currentState = currentState.copyWith(theoryState: stream)),
      exerciseStream.map((stream) => currentState = currentState.copyWith(exerciseState: stream)),
    ]);

  }
}*/
mixin ActionExecutor {
  Stream<D> run<D extends DataState>(ActionUnit<D> usecase, D current) {
    return usecase.execute(current);
  }
}

/// Chứa sự kiện thực hiện có tác động và trả về 1 trạng thái mới
/// Ví dụ:
/*abstract class TheoryAction extends ActionUnit<TheoryState> {
  final List<Theory> repository = [
    Theory(id: 1, subjectId: 1, content: 'content', title: 'title'),
    Theory(id: 2, subjectId: 1, content: 'content', title: 'title'),
  ];
}

class LoadTheoryBySubjectId extends TheoryAction {
  final int subjectId;

  LoadTheoryBySubjectId(this.subjectId);

  @override
  Stream<TheoryState> execute(TheoryState current) async* {
    yield current.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 3));
    yield current.copyWith(theories: repository, isLoading: false);
  }
}*/

/// Kết hợp stream thực hiện song song, đồng thời
/*
    yield* merge([
     theoryStream.map((stream) => currentState = currentState.copyWith(theoryState: stream)),
      exerciseStream.map((stream) => currentState = currentState.copyWith(exerciseState: stream)),
    ]);

* */
mixin ActionMerge {
  Stream<T> merge<T>(List<Stream<T>> streams) {
    final controller = StreamController<T>();

    int activeStreams = streams.length;

    for (final stream in streams) {
      stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          activeStreams--;
          if (activeStreams == 0) {
            controller.close();
          }
        },
        cancelOnError: false,
      );
    }

    return controller.stream;
  }
}

abstract class ActionUnit<T extends DataState> {
  late void Function(T newState) emit;
  Stream<T> execute(T current);

  @mustCallSuper
  void dispose() {}
}

//--------------------------------NGƯỜI XỬ LÝ-------------------------------
/// Nó sẽ chịu trách nhiệm xử lý cho 1 trạng thái [DataState] cụ thể
/// Thực hiện và lắng nghe các [ActionUnit] được UI gửi tới
///
class Performer<Data extends DataState> {
  final _streamController = StreamController<Data>.broadcast();
  final _usecaseQueue    = StreamController<ActionUnit<Data>>();
  final Set<ActionUnit<Data>> _activeUsecases = {};

  Data _data;

  Performer({required Data data}) : _data = data {
    _startQueueProcessor();
  }

  /// Stream of states
  Stream<Data> get stream => _streamController.stream;

  /// Current state
  Data get current => _data;

  /// Dispatch một usecase vào queue
  void add(ActionUnit<Data> usecase) {
    _usecaseQueue.add(usecase);
  }

  /// Cập nhật state và emit nếu khác state cũ
  void _newState(Data data) {
    if (data != _data && !_streamController.isClosed) {
      _data = data;
      _streamController.add(data);
    }
  }

  /// Xử lý tuần tự các usecase trong queue
  void _startQueueProcessor() {
    _usecaseQueue.stream.listen((usecase) {
      _activeUsecases.add(usecase);

      // 1) Controller gom các state emit
      final controller = StreamController<Data>();

      // 2) Gán emit() để usecase call vào controller
      usecase.emit = (Data newState) {
        controller.add(newState);
      };

      // 3) Chạy execute(), chuyển vào broadcast stream
      final execStream = usecase.execute(_data).asBroadcastStream();

      // khi execStream có dữ liệu hoặc hoàn tất → forward vào controller
      final subExec = execStream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          controller.close();            // đóng controller khi execStream done
        },
        cancelOnError: false,
      );

      // 4) Lắng nghe controller để update state và cleanup khi xong
      controller.stream.listen(
            (state) {
          _newState(state);
        },
        onDone: () {
          _activeUsecases.remove(usecase);
          usecase.dispose();
          subExec.cancel();              // huỷ subscription của execStream
        },
      );
    });
  }

  /// Dispose performer: đóng stream, queue và dispose các usecase đang chạy
  void dispose() {
    // 1) Đóng stream kết quả
    _streamController.close();

    // 2) Đóng queue để không nhận thêm usecase
    _usecaseQueue.close();

    // 3) Gọi dispose() lên từng usecase còn active
    for (var uc in _activeUsecases) {
      uc.dispose();
    }
    _activeUsecases.clear();
  }
}