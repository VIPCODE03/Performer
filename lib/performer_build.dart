import 'package:flutter/widgets.dart';
import 'package:performer/performer.dart';

class PerformerProvider<P extends Performer> extends StatefulWidget {
  final P Function() create;
  final Widget child;

  const PerformerProvider({
    super.key,
    required this.create,
    required this.child,
  });

  @override
  State<PerformerProvider<P>> createState() => _PerformerProviderState<P>();

  static P of<P extends Performer>(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_PerformerInherited<P>>();
    assert(inherited != null, 'PerformerProvider<$P> not found in context');
    return inherited!.conductor;
  }
}

class _PerformerProviderState<P extends Performer> extends State<PerformerProvider<P>> {
  late P _conductor;

  @override
  void initState() {
    super.initState();
    _conductor = widget.create();
  }

  @override
  void dispose() {
    _conductor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PerformerInherited<P>(
      conductor: _conductor,
      child: widget.child,
    );
  }
}

class _PerformerInherited<P extends Performer> extends InheritedWidget {
  final P conductor;

  const _PerformerInherited({
    required this.conductor,
    required super.child,
  });

  @override
  bool updateShouldNotify(_PerformerInherited<P> oldWidget) => false;
}

class ConductorBuilder<P extends Performer> extends StatelessWidget {
  final Widget Function(BuildContext context, P conductor) builder;

  const ConductorBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final conductor = PerformerProvider.of<P>(context);

    return StreamBuilder<DataState>(
      stream: conductor.stream,
      initialData: conductor.current,
      builder: (context, snapshot) {
        return builder(context, conductor);
      },
    );
  }
}
