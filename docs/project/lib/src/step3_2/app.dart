import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memojudge/src/library/model_view_viewmodel_container.dart';

/// step3-2
void startApp() {
  runApp(MyApp());
}

// 独自 MVVM パッケージを使った、MVVM パターン実装
// CountModelを CountViewModelと TenCounterViewModelにバインド(所有)させて、
// CountViewに CountViewModel、TenCounterViewに TenCounterViewModelをバインドして、
// CountModelは、全体の関心事(カウント操作と、更新通知⇒バインド元への一斉通知)のみに専念することで、
// View Model側は、自分の表示ルール⇒ロジックに従った、Modelから UI状態への反映と UI表示の更新を行い、
// View側での ボタンクリックごとの カウント増加と、10カウントごとの CLEAR 表示の連携を実現しています。

/// ページ全体のモデル（ビジネスロジックとデータモデル）を提供するモデルコンテナ
class MyHomeModelContainer with PageModelContainer {
  CountModel countModel;
  AutoCountViewModel auto;
  CountViewModel count;
  TenCounterViewModel tenCounter;

  @override
  ViewModels initModel() {
    countModel = CountModel();
    auto = AutoCountViewModel(countModel);
    count = CountViewModel(countModel);
    tenCounter = TenCounterViewModel(countModel);
    return ViewModels([
      auto,
      count,
      tenCounter], this);
  }

  @override
  void initPage(BuildContext context) {}
}

/// カウントを管理する Model
class CountModel extends Model {
  CountModel(): super();

  bool isAutoCountUpStarted = false;
  int _count = 0;
  int get count => _count;

  void incrementCounter() {
    _count++;
    updateViewModels();
  }

  void startAutoIncrement(bool isUseTimer) {
    // メインとは別の Isolate で、自動インクリメントを実行させる。
    Future(() {
      autoIncrementToTwenty(isUseTimer);
    });
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
class AutoCountViewModel extends ViewModel {
  final CountModel countModel;
  AutoCountViewModel(this.countModel) :super() {
    countModel.bindUpdate(onUpdate);
  }

  void startAutoIncrement(bool isUseTimer) {
    countModel.startAutoIncrement(isUseTimer);
  }
}

/// カウントの UI表示に関する、プロパティとコマンドを提供する ViewModel
class CountViewModel extends ViewModel {
  final CountModel countModel;
  CountViewModel(this.countModel) : super() {
    countModel.bindUpdate(onUpdate);
  }

  int get count => countModel.count;

  void updateCount(bool isUseTimer) {
    countModel.autoIncrementToTwenty(isUseTimer);
  }

  @override
  void onUpdate(Model model) {
    if (model?.hashCode == countModel.hashCode ?? false) {
      updateView();
    }
  }
}

/// 10カウントごとの UI表示に関する、プロパティとコマンドを提供する ViewModel
class TenCounterViewModel extends ViewModel {
  final CountModel countModel;
  TenCounterViewModel(this.countModel) : super() {
    countModel.bindUpdate(onUpdate);
  }

  bool _isAnimate = false;
  bool get isAnimate => _isAnimate;

  /// 10カウントごとに バインド先の UI表示切替を行う
  void displayForEvery10Counts(int count) {
    if (count % 10 == 0) {
      // カウントが 10 ごとに表示する。
      _isAnimate = true;
      updateView();
    } else
    if (_isAnimate == true) {
      // カウントが 10 ごとでないのなら表示しない。
      _isAnimate = false;
      updateView();
    }
  }

  @override
  void onUpdate(Model model) {
    if (model?.hashCode == countModel.hashCode ?? false) {
      displayForEvery10Counts(countModel.count);
    }
  }
}

class MyApp extends AppWidget {
  @override
  Widget build(BuildContext context, modelContainer) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends PageWidget<MyHomeModelContainer> {
  const MyHomePage({
    Key key,
    this.title,
  }) : super(key: key);
  final String title;

  @override
  MyHomeModelContainer createModelContainer() {
    return MyHomeModelContainer();
  }

  @override
  Widget build(BuildContext context, ViewModels viewModels) {
    viewModels.find<AutoCountViewModel>().startAutoIncrement(true);
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
              children: <Widget>[
                const Text(
                  'You have pushed the button this many times:',
                ),
                // カウントの UI表示を行う View
                ViewWidget<CountViewModel>(
                    model: viewModels.find<CountViewModel>(),
                    builder: (BuildContext context, CountViewModel model) {
                      return Text(
                        '${model.count}',
                        style: Theme.of(context).textTheme.headline4,
                      );
                    }
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              alignment: Alignment.center,
              color: Colors.transparent,
              // 10カウントごとの UI表示を行う View
              child: ViewWidget<TenCounterViewModel>(
                  model: viewModels.find<TenCounterViewModel>(),
                  builder: (BuildContext context, TenCounterViewModel model) {
                    return TenCounterAnimationView(isAnimate: model.isAnimate);
                  }
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(child:
            FloatingActionButton(
              onPressed: () => viewModels.find<CountViewModel>().updateCount(true),
              tooltip: 'auto increment by Timer.periodic',
              child: const Icon(Icons.add),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          ),
          Expanded(child:
            FloatingActionButton(
              onPressed: () => viewModels.find<CountViewModel>().updateCount(false),
              tooltip: 'auto increment by Future.delayed',
              child: const Icon(Icons.add),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          ),
        ],
      ),
    );
  }
}

/// 10カウントごとの UI表示を行う AnimationView
class TenCounterAnimationView extends StatefulWidget {
  final bool isAnimate;

  const TenCounterAnimationView({
    Key key,
    @required this.isAnimate,
  }) : super(key: key);

  @override
  _TenCounterAnimationViewState createState() => _TenCounterAnimationViewState();
}
class _TenCounterAnimationViewState extends State<TenCounterAnimationView>
    with TickerProviderStateMixin {
  _TenCounterAnimationViewState() : super();

  // 独自追加アニメーションオブジェクト
  AnimationController controller;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  @override
  void dispose() {
    _disposeAnimation();
    super.dispose();
  }

  void _initAnimation() {
    controller = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this)
      ..forward();
    animation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(
          CurvedAnimation(
            parent: controller,
            curve: Curves.easeOutQuart),
        );
  }

  void _disposeAnimation() {
    controller?.stop();
    controller?.dispose();
    controller = null;
  }

  @override
  Widget build(BuildContext context) {
    // アニメ実行済の場合は、再初期化を実行する。
    if (controller?.isCompleted ?? false) {
      _disposeAnimation();
      _initAnimation();
    }

    // trueになったときのみアニメを実行させます。
    if (widget.isAnimate) {
      // Alignment は、左端/上端が-1.0 で 右端/下端が 1.0 の位置を表す座標系なので、
      // Alignmentの x は、0.0 ⇒ 中央固定で、y を 1.0 〜 0.0 まで変化させて、
      // 画面下端から中央に移動させます。
      return AnimatedBuilder(
          builder: (BuildContext context, Widget child) {
            return Align(
              alignment: Alignment(0.0, animation.value),
              child: const Text(
                  'CLEAR',
                  style: TextStyle(
                      fontSize: 50.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber),
              ),
            );
          },
          animation: controller,
          child: null,
      );

    } else {
      return const SizedBox.shrink();
    }
  }
}
