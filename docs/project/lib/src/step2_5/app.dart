import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memojudge/src/library/model_mixin.dart';

/// step2-5
void startApp() {
  runApp(MyApp());
}

// provider パッケージ＋ViewModel＆Modelを使った、MVVM パターン実装
// CountModelを CountViewModelと TenCounterViewModelにバインド(所有)させて、
// CountViewに CountViewModel、TenCounterViewに TenCounterViewModelをバインドして、
// CountModelは、全体の関心事(カウント操作と、更新通知⇒バインド元への一斉通知)のみに専念することで、
// View Model側は、自分の表示ルール⇒ロジックに従った、Modelから UI状態への反映と UI表示の更新を行い、
// View側での ボタンクリックごとの カウント増加と、10カウントごとの CLEAR 表示の連携を実現しています。

/// ページ全体にモデル（ビジネスロジックとデータモデル）を提供する Provider
class MyHomeProvider {
  CountModel countModel;
  CountViewModel count;
  TenCounterViewModel tenCounter;

  Widget create() {
    countModel = CountModel();
    count = CountViewModel(countModel);
    tenCounter = TenCounterViewModel(countModel);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => count),
        ChangeNotifierProvider(create: (context) => tenCounter),
      ],
      child: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

/// カウントを管理する Model
class CountModel with Model {
  bool isAutoCountUpStarted = false;
  int _count = 0;
  int get count => _count;

  void incrementCounter() {
    _count++;
    updateViewModels();
  }

  void autoIncrementToTwenty(bool isUseTimer) {
    if (isAutoCountUpStarted) {
      return;
    }

    isAutoCountUpStarted = true;
    if (isUseTimer) {
      _incrementToTwentyByTimer();
    } else {
      _incrementToTwentyByAwait();
    }
  }

  /// カウンターが20になるまで、1秒毎に incrementCounter() を実行。（Timer.periodic 版）
  void _incrementToTwentyByTimer() {
    _count = 0;

    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (count < 20) {
        incrementCounter();
      } else {
        timer.cancel();
        isAutoCountUpStarted = false;
      }
    });
  }

  /// カウンターが20になるまで、1秒毎に incrementCounter() を実行。（Future.delayed 版）
  Future<void> _incrementToTwentyByAwait() async {
    _count = 0;

    Future<void> asyncWait() {
      final Future<void> future = Future.delayed(const Duration(seconds: 1));
      return future;
    }

    while(count < 20) {
      incrementCounter();
      await asyncWait();
    }
    isAutoCountUpStarted = false;
  }
}

/// カウントの UI表示に関する、プロパティとコマンドを提供する ViewModel
class CountViewModel with ChangeNotifier, ViewModel {
  final CountModel countModel;
  CountViewModel(this.countModel) {
    countModel.bindUpdate(onUpdate);
  }

  int get count => countModel.count;

  void updateCount(bool isUseTimer) {
    countModel.autoIncrementToTwenty(isUseTimer);
  }

  @override
  void onUpdate(Model model) {
    if (model?.hashCode == countModel.hashCode ?? false) {
      notifyListeners();
    }
  }
}

/// 10カウントごとの UI表示に関する、プロパティとコマンドを提供する ViewModel
class TenCounterViewModel with ChangeNotifier, ViewModel {
  final CountModel countModel;
  TenCounterViewModel(this.countModel) {
    countModel.bindUpdate(onUpdate);
  }

  bool _isAnimate = false;
  bool get isAnimate => _isAnimate;

  /// 10カウントごとに バインド先の UI表示切替を行う
  void displayForEvery10Counts(int count) {
    if (count % 10 == 0) {
      // カウントが 10 ごとに表示する。
      _isAnimate = true;
      notifyListeners();
    } else
    if (_isAnimate == true) {
      // カウントが 10 ごとでないのなら表示しない。
      _isAnimate = false;
      notifyListeners();
    }
  }

  @override
  void onUpdate(Model model) {
    if (model?.hashCode == countModel.hashCode ?? false) {
      displayForEvery10Counts(countModel.count);
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomeProvider().create(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    Key key,
    this.title,
  }) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Stack(
        fit:StackFit.loose,
        overflow: Overflow.clip,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Text(
                  'You have pushed the button this many times:',
                ),
                // カウントの UI表示を行う View
                CountView(),
              ],
            ),
          ),
          Center(
            child: Container(
              alignment: Alignment.center,
              color: Colors.transparent,
              // 10カウントごとの UI表示を行う View
              child: const TenCounterView(),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(child:
            FloatingActionButton(
              onPressed: () => context.read<CountViewModel>().updateCount(true),
              tooltip: 'auto increment by Timer.periodic',
              child: const Icon(Icons.add),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          ),
          Expanded(child:
            FloatingActionButton(
              onPressed: () => context.read<CountViewModel>().updateCount(false),
              tooltip: 'auto increment by Future.delayed',
              child: const Icon(Icons.add),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          ),
        ],
      ),
    );
  }
}

/// カウントの UI表示を行う View
class CountView extends StatelessWidget {
  const CountView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      '${context.watch<CountViewModel>().count}',
      style: Theme.of(context).textTheme.headline4,
    );
  }
}

/// 10カウントごとの UI表示を行う View
class TenCounterView extends StatelessWidget {
  const TenCounterView({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // trueになったときのみ表示させます。
    if (context.watch<TenCounterViewModel>().isAnimate) {
      return Builder(
          builder: (BuildContext context) {
            return const Align(
              alignment: Alignment(0.0, 0.0),
              child: Text(
                  'CLEAR',
                  style: TextStyle(
                      fontSize: 50.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber),
              ),
            );
          },
      );

    } else {
      return const SizedBox.shrink();
    }
  }
}
