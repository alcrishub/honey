import 'dart:async';
import 'dart:collection';

import 'package:honey/honey.dart';
import 'package:honey/src/honey_widgets_binding.dart';
import 'package:honey/src/expression/expr.dart';
import 'package:honey/src/expression/statement.dart';
import 'package:honey/src/runner/context/runtime_honey_context.dart';
import 'package:honey/src/runner/errors/honey_error.dart';
import 'package:honey/src/runner/errors/unknown_error.dart';
import 'package:honey/src/utils/fake_text_input.dart';

class TestRunner {
  TestRunner(this.runId, this.expressions);

  final int runId;
  final List<Statement> expressions;
  final _fakeInput = FakeTextInput();
  var _canceled = false;
  late var _ctx = RuntimeHoneyContext(_fakeInput);

  Stream<void> executeAll() async* {
    final queue = ListQueue.of(expressions.reversed);
    const stepIndex = 0;
    while (queue.isNotEmpty && !_canceled) {
      final expression = queue.removeLast();

      //final dynamic result = await runRepeatedly(expression);

      /*final step = TestStep(
        runId: runId,
        time: DateTime.now().difference(startTime).inMilliseconds,
        index: stepIndex++,
        step: statement.sourceInfo.source,
        message: result is HoneyError ? result.message : _ctx.message,
        error: result is HoneyError && !statement.optional,
        variables: Map.of(_ctx.variables),
      );
      if (!_canceled) {
        yield step;
      }*/

      /*if (result is HoneyError) {
        return;
      }*/
    }
  }

  Future<dynamic> runRepeatedly(
    Expr expression, {
    bool untilTrue = false,
  }) async {
    await HoneyWidgetsBinding.instance
        .waitUntilSettled(const Duration(seconds: 10));
    final startCtx = _ctx;

    final s = Stopwatch()..start();
    while (true) {
      //final timeout = (await _ctx.getVariable('timeout')).asNum;
      await Future<void>.delayed(const Duration(milliseconds: 100));

      _ctx = startCtx.clone();
      HoneyError? error;
      Expr? value;
      try {
        value = await _ctx.eval(expression);
      } on HoneyError catch (e) {
        error = e;
      } catch (e, s) {
        error = UnknownError('$e $s');
      }
      /*if (error != null) {
        if (!error.retry) {
          return error;
        }
      } else if (value!.asBool || !untilTrue) {
        return value;
      } else if (!value.retry) {
        return value;
      }

      if (s.elapsed.inMilliseconds > timeout || _canceled) {
        return error ?? value;
      }*/
    }
  }

  Future<void> cancel() async {
    _canceled = true;
  }

  void dispose() {
    _fakeInput.dispose();
  }

  Future<dynamic> _runCondition(
      ConditionStatement statement, ListQueue<Statement> queue) async {
    var isConditionMet = false;
    dynamic result;
    for (final conditionalStatement
        in statement.conditionStatements ?? <ConditionStatementItem>[]) {
      if (conditionalStatement.condition != null) {
        result = await runRepeatedly(
          conditionalStatement.condition!,
        );
        isConditionMet = result is ValueExpr && result.asBool;
        if (isConditionMet) {
          queue.addAll(conditionalStatement.statements);
          break;
        }
      } else {
        queue.addAll(conditionalStatement.statements);
      }
    }
    return result;
  }
}
