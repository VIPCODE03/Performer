import 'package:flutter/widgets.dart';
import 'package:performer/performer.dart';

typedef Create<P extends Performer> = P Function(BuildContext context);

class PerformerProvider<P extends Performer> extends StatefulWidget {
  final Create<P> create;
  final Widget? child;

  const PerformerProvider({
    super.key,
    required this.create,
    this.child,
  });

  @override
  State<PerformerProvider<P>> createState() => _PerformerProviderState<P>();

  static P of<P extends Performer>(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_PerformerInherited<P>>();
    assert(inherited != null, 'PerformerProvider<$P> not found in context');
    return inherited!.performer;
  }
}

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
      return PerformerProvider(
        key: provider.key,
        create: provider.create,
        child: child,
      );
    }
    throw ArgumentError('Only PerformerProvider widgets are allowed');
  }
}

class _PerformerProviderState<P extends Performer> extends State<PerformerProvider<P>> {
  late final P _performer;

  @override
  void initState() {
    super.initState();
    _performer = widget.create(context);
  }

  @override
  void dispose() {
    _performer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PerformerInherited<P>(
      performer: _performer,
      child: widget.child ?? SizedBox.shrink(),
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
