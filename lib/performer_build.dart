import 'package:flutter/widgets.dart';
import 'package:performer/performer.dart';

typedef Create<P extends Performer> = P Function(BuildContext context);

class PerformerProvider<P extends Performer> extends StatefulWidget {
  final P Function(BuildContext context)? _creator;
  final P? _externalPerformer;
  final bool _dispose;
  final Widget? child;

  const PerformerProvider.create({
    super.key,
    required P Function(BuildContext context) create,
    this.child,
  })  : _creator = create,
        _externalPerformer = null,
        _dispose = true;

  const PerformerProvider.external({
    super.key,
    required P performer,
    bool dispose = false,
    this.child,
  })  : _creator = null,
        _externalPerformer = performer,
        _dispose = dispose;

  @override
  State<PerformerProvider<P>> createState() => _PerformerProviderState<P>();

  static P of<P extends Performer>(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_PerformerInherited<P>>();
    assert(inherited != null, 'PerformerProvider<$P> not found in context');
    return inherited!.performer;
  }
}

class _PerformerProviderState<P extends Performer> extends State<PerformerProvider<P>> {
  late final P _performer;

  @override
  void initState() {
    super.initState();
    if (widget._creator != null) {
      _performer = widget._creator!(context);
    } else if (widget._externalPerformer != null) {
      _performer = widget._externalPerformer!;
    } else {
      throw StateError('Either a creator or an external performer must be provided.');
    }
  }

  @override
  void dispose() {
    if (widget._dispose) {
      _performer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PerformerInherited<P>(
      performer: _performer,
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}

class _PerformerInherited<P extends Performer> extends InheritedWidget {
  final P performer;

  const _PerformerInherited({
    required this.performer,
    required super.child,
  });

  @override
  bool updateShouldNotify(_PerformerInherited<P> oldWidget) => false;
}

/// ----------------------------------------------------------------------------
/// Build widget theo state
/// Tự động tìm [Performer] nếu có ở widget cha
/// ----------------------------------------------------------------------------
class PerformerBuilder<P extends Performer> extends StatelessWidget {
  final Widget Function(BuildContext context, P performer) builder;

  const PerformerBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final performer = PerformerProvider.of<P>(context);

    return StreamBuilder<DataState>(
      stream: performer.stream,
      initialData: performer.current,
      builder: (context, snapshot) {
        return builder(context, performer);
      },
    );
  }
}

/*
class MultiPerformerProvider extends StatelessWidget {
  final List<Widget> providers;
  final Widget child;

  const MultiPerformerProvider({
    super.key,
    required this.providers,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget current = child;
    for (final provider in providers.reversed) {
      current = _wrapWith(provider, current);
    }
    return current;
  }

  Widget _wrapWith(Widget provider, Widget child) {
    if (provider is PerformerProvider) {
      return PerformerProvider.create(
        key: provider.key,
        create: provider.create,
        child: child,
      );
    }
    throw ArgumentError('Only PerformerProvider widgets are allowed');
  }
}
*/
