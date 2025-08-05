import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:source_maps/refactor.dart';
import 'package:source_span/source_span.dart';

abstract class MacrolyzerPlugin<T extends MacrolyzerPluginContext> {
  String get name;
  String get version;

  Future<T> check(
    ResolvedUnitResult unit, {
    required AnalysisSession session,
    required SourceFile source,
  });

  Future<bool> transform(
    TextEditTransaction edit,
    ResolvedUnitResult unit, {
    required AnalysisSession session,
    required T context,
    bool isDeclaration = false,
  });
}

abstract class MacrolyzerPluginContext {}
