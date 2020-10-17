import 'dart:async';

import 'package:flutter/material.dart';

/// step3-3
void main() {
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
  TenCounterAnimationViewModel tenCounter;

  @override
  ViewModels initModel() {
    countModel = CountModel();
    auto = AutoCountViewModel(countModel);
    count = CountViewModel(countModel);
    tenCounter = TenCounterAnimationViewModel(countModel);
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

/// 10カウントごとの UI表示に関する、プロパティとコマンドを提供する AnimationViewModel
class TenCounterAnimationViewModel extends AnimationViewModel {
  final CountModel countModel;
  TenCounterAnimationViewModel(this.countModel) : super(isAnimate: false) {
    countModel.bindUpdate(onUpdate);
  }

  bool get isClear => isAnimate;

  /// 10カウントごとに バインド先の UI表示切替を行う
  void displayForEvery10Counts(int count) {
    if (count % 10 == 0) {
      // カウントが 10 ごとに表示する。
      isAnimate = true;
      updateView();
    } else
    if (isAnimate == true) {
      // カウントが 10 ごとでないのなら表示しない。
      isAnimate = false;
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
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'You have pushed the button this many times:',
                ),
                // カウントの UI表示を行う View
                CountView(model: viewModels.find<CountViewModel>()),
              ],
            ),
          ),
          Center(
            child: Container(
              alignment: Alignment.center,
              color: Colors.transparent,
              // 10カウントごとの UI表示を行う AnimationView
              child: TenCounterAnimationView(model: viewModels.find<TenCounterAnimationViewModel>()),
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
          ),
          ),
          Expanded(child:
          FloatingActionButton(
            onPressed: () => viewModels.find<CountViewModel>().updateCount(false),
            tooltip: 'auto increment by Future.delayed',
            child: const Icon(Icons.add),
          ),
          ),
        ],
      ),
    );
  }
}

/// カウントの UI表示を行う View
class CountView extends AbstractViewWidget<CountViewModel> {
  const CountView({
    Key key,
    @required CountViewModel model,
  }) : super(key: key, model: model);

  @override
  Widget build(BuildContext context, CountViewModel model) {
    return Text(
      '${model.count}',
      style: Theme.of(context).textTheme.headline4,
    );
  }
}

/// 10カウントごとの UI表示を行う AnimationView
class TenCounterAnimationView extends AbstractAnimationViewWidget<TenCounterAnimationViewModel> {
  const TenCounterAnimationView({
    Key key,
    @required TenCounterAnimationViewModel model,
  }) : super(key: key, model: model);

  @override
  AnimationController onCreateController(TickerProvider vsync) {
    return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: vsync)
      ..forward();
  }

  @override
  List<Animation> onCreateAnimations(AnimationController controller) {
    final Animation<double> animation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(
      CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutQuart),
    );
    return <Animation>[animation];
  }

  @override
  Widget onCreateChild(BuildContext context) {
    return null;
  }

  @override
  Widget onAnimationBuild(BuildContext context, Widget child,
      AnimationController controller, List<Animation> animations, {TenCounterAnimationViewModel model}) {
    final Animation<double> animation = convertAnimation(animations[0]);
    // Alignment は、左端/上端が-1.0 で 右端/下端が 1.0 の位置を表す座標系なので、
    // Alignmentの x は、0.0 ⇒ 中央固定で、y を 1.0 〜 0.0 まで変化させて、
    // 画面下端から中央に移動させます。
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
  }

  @override
  Widget noAnimationBuild(BuildContext context, Widget child, {TenCounterAnimationViewModel model}) {
    return const SizedBox.shrink();
  }
}


// ＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊
// 独自MVVMライブラリ
// ＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊
/// UI表現モデルを更新させるための関数型
typedef UpdateViewModel = void Function(Model model);

/// UI表現を更新させるための関数型
typedef UpdateView = void Function();

/// UI表現を更新させ、完了まで待機させるための関数型
typedef AsyncUpdateView = Future<bool> Function();

/// UI表現を構築するための関数型
typedef ViewBuilder<M extends ViewModel> = Widget Function(BuildContext context, M model);

/// voidを返し引数がない関数型
typedef VoidFunction = void Function();


/// アプリ全体の Model を管理するモデルコンテナのミキシイン(抽象基盤クラスの素)。
mixin AppModelContainer {
  /// アプリ全体で管理する Model の初期設定を行います。
  void initModel();

  /// アプリ全体に関わる初期設定を行います。
  void initApp(BuildContext context);
}

/// アプリ全体のウィジェット定義と<br/>
/// アプリ全体のモデルコンテナ([AppModelContainer]継承型オブジェクト)を指定する抽象基盤クラス。
abstract class AppWidget<M extends AppModelContainer> extends StatefulWidget {
  const AppWidget({
    Key key,
  }) : super(key: key);

  void initState(){}
  void dispose(){}

  /// AppModelContainer継承オブジェクト生成
  M createModelContainer() {
    return null;
  }

  M _createModelContainer() {
    final M appModelContainer = createModelContainer();
    appModelContainer?.initModel();
    return appModelContainer;
  }

  Widget build(BuildContext context, M modelContainer);

  @override
  AppWidgetState<M> createState() => AppWidgetState<M>(_createModelContainer());
}
class AppWidgetState<M extends AppModelContainer> extends State<AppWidget<M>> {
  final M modelContainer;
  AppWidgetState(this.modelContainer) : super();

  @override
  void initState(){
    super.initState();
    widget.initState();
  }

  @override
  void dispose(){
    widget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    modelContainer?.initApp(context);
    return widget.build(context, modelContainer);
  }
}


/// ページ全体の ViewModel や Model を管理するモデルコンテナのミキシイン(抽象基盤クラスの素)。
mixin PageModelContainer {
  /// ページ全体で公開する ViewModel 一覧
  ViewModels viewModels;

  /// ページ全体で管理するモデル値の初期設定を行います。
  ViewModels initModel();

  /// ページ全体に関わる初期設定を行います。
  void initPage(BuildContext context);

  /// AppModelContainer継承オブジェクト提供
  M provideAppModelContainer<M extends AppModelContainer>(BuildContext context) {
    final AppWidgetState<M> state = context.findAncestorStateOfType<AppWidgetState<M>>();
    return state?.modelContainer;
  }
}

/// ページ全体のUI表現の定義と<br/>
/// ページ全体のモデルコンテナ([PageModelContainer]継承型オブジェクト)を指定する抽象基盤クラス。
abstract class PageWidget<M extends PageModelContainer> extends StatefulWidget {
  const PageWidget({
    Key key,
  }) : super(key: key);

  void initState(){}
  void dispose(){}

  /// PageModelContainer継承オブジェクト生成
  M createModelContainer() {
    return null;
  }

  M _createModelContainer() {
    final M pageModelContainer = createModelContainer();
    pageModelContainer.viewModels = pageModelContainer?.initModel();
    return pageModelContainer;
  }

  Widget build(BuildContext context, ViewModels viewModels);

  @override
  _BasePageWidgetState<M> createState() => _BasePageWidgetState<M>(_createModelContainer());
}
class _BasePageWidgetState<M extends PageModelContainer> extends State<PageWidget<M>> {
  final M modelContainer;
  _BasePageWidgetState(this.modelContainer) : super();

  @override
  void initState(){
    super.initState();
    if (widget.initState != null) {
      widget.initState();
    }
  }

  @override
  void dispose(){
    if (widget.dispose != null) {
      widget.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    modelContainer?.initPage(context);
    return widget.build(context, modelContainer?.viewModels);
  }
}

/// ビジネスロジックとデータモデルを提供する、ドメインモデルを定義する基盤クラス。
abstract class Model {
  final List<UpdateViewModel> _updateViewModels = [];

  /// UI表現モデル更新関数を登録する。
  void bindUpdate(UpdateViewModel updateViewModel) {
    if (updateViewModel != null) {
      _updateViewModels.add(updateViewModel);
    }
  }

  /// UI表現モデル更新関数を削除する。
  void unbindUpdate(UpdateViewModel updateViewModel) {
    if (updateViewModel != null) {
      _updateViewModels.remove(updateViewModel);
    }
  }

  /// UI表現モデルを更新する。
  void updateViewModels() {
    if (_updateViewModels != null) {
      for (UpdateViewModel update in _updateViewModels) {
        update(this);
      }
    }
  }
}

/// テキストメセージなどのUI個別表現の状態を扱う基盤クラス。
class ViewModel<T> {
  UpdateView _updateView;
  T value;
  ViewModel({
    this.value
  }) : super();

  /// UI表現を更新する。
  void updateView() {
    if (_updateView != null) {
      _updateView();
    }
  }

  /// UI個別表現の状態を更新するハンドラ。
  void onUpdate(Model model) {}

  /// モデルと更新ハンドラをバインドする。
  void bindModel(Model model) {
    model.bindUpdate(onUpdate);
  }

  /// モデルと更新ハンドラをアンバインドする。
  void unbindModel(Model model) {
    model.unbindUpdate(onUpdate);
  }
}

/// アニメーション(ON/OFF)指定付きのUI個別表現の状態を扱う基盤クラス。
class AnimationViewModel<T> extends ViewModel<T> {
  bool isAnimate;
  AsyncUpdateView _asyncUpdateView;

  AnimationViewModel({
    @required this.isAnimate,
    T value
  }) : super(value: value);

  /// UI表現を更新し、アニメーション表示完了まで待機する。
  Future<bool> asyncUpdateView() {
    if (_asyncUpdateView != null) {
      return _asyncUpdateView();
    }
    return Future<bool>.value(false);
  }
}

/// ViewModel の一覧を格納する基盤クラス
class ViewModels {
  final PageModelContainer _pageModelContainer;
  final Map<Type,ViewModel> _viewModelMap;
  final List<ViewModel> _viewModels;

  ViewModels(
      this._viewModels,
      PageModelContainer pageModelContainer,
      ) : _viewModelMap = _parseMap(_viewModels),
        _pageModelContainer = pageModelContainer;

  M unsafePageModelContainer<M extends PageModelContainer>() {
    return _pageModelContainer as M;
  }

  /// 指定 index の ViewModel要素取得
  T get<T extends ViewModel>(int index) {
    return _viewModels[index] as T;
  }

  /// 指定 ViewModel型 の ViewModel要素取得
  T find<T extends ViewModel>() {
    return _viewModelMap[T] as T;
  }

  static Map<Type,ViewModel> _parseMap(List<ViewModel> models) {
    final Map<Type,ViewModel> viewModelMap = {};
    for(ViewModel model in models) {
      final Type type = model.runtimeType;
      viewModelMap[type] = model;
    }
    return viewModelMap;
  }
}

/// ページ内の個別のUI表現の定義と利用する View Model([ViewModel])を指定する基盤クラス。
class ViewWidget<M extends ViewModel> extends AbstractViewWidget<M> {
  final ViewBuilder<M> builder;
  final VoidFunction initStater;
  final VoidFunction disposer;

  const ViewWidget({
    Key key,
    @required M model,
    @required this.builder,
    this.initStater,
    this.disposer,
  }) : super(key: key, model: model);

  @override
  void initState() {
    if (initStater != null) {
      initStater();
    }
  }

  @override
  void dispose() {
    if (disposer != null) {
      disposer();
    }
  }

  @override
  Widget build(BuildContext context, M model) {
    return builder(context, model);
  }

  @override
  _AbstractViewWidgetState createState() => _AbstractViewWidgetState();
}


// ビルド関数の引数 model がオプションになっていることに注意！
class AnimationViewWidget<M extends AnimationViewModel> extends AbstractAnimationViewWidget<M> {
  final VoidFunction initStater;
  final VoidFunction disposer;
  final AnimationController Function(TickerProvider vsync) onCreatorController;
  final List<Animation> Function(AnimationController controller) onCreatorAnimations;
  final Widget Function(BuildContext context) onCreatorChild;
  final Widget Function(BuildContext context, Widget child, AnimationController controller, List<Animation> animations, {M model}) onAnimationBuilder;
  final Widget Function(BuildContext context, Widget child, {M model}) noAnimationBuilder;

  const AnimationViewWidget({
    Key key,
    @required M model,
    @required this.onCreatorController,
    @required this.onCreatorAnimations,
    @required this.onCreatorChild,
    @required this.onAnimationBuilder,
    @required this.noAnimationBuilder,
    this.initStater,
    this.disposer,
  }) : super(key: key, model: model);

  @override
  void initState() {
    if (initStater != null) {
      initStater();
    }
  }

  @override
  void dispose() {
    if (disposer != null) {
      disposer();
    }
  }

  /// アニメーションリスト要素の型キャスト
  static Animation<V> converterAnimation<V>(Animation<dynamic> animation) {
    return animation as Animation<V>;
  }

  @override
  AnimationController onCreateController(TickerProvider vsync) {
    return onCreatorController(vsync);
  }

  @override
  List<Animation> onCreateAnimations(AnimationController controller) {
    return onCreatorAnimations(controller);
  }

  @override
  Widget onCreateChild(BuildContext context) {
    return onCreatorChild(context);
  }

  @override
  Widget onAnimationBuild(BuildContext context, Widget child, AnimationController controller, List<Animation> animations, {M model}) {
    return onAnimationBuilder(context, child, controller, animations, model: model);
  }

  @override
  Widget noAnimationBuild(BuildContext context, Widget child, {M model}) {
    return noAnimationBuilder(context, child, model: model);
  }

  @override
  _AbstractAnimationViewWidgetState createState() => _AbstractAnimationViewWidgetState();
}


abstract class AbstractViewWidget<M extends ViewModel> extends StatefulWidget {
  final M model;
  const AbstractViewWidget({
    Key key,
    @required this.model,
  }) : super(key: key);

  void initState(){}
  void dispose(){}
  Widget build(BuildContext context, M model);

  @override
  _AbstractViewWidgetState createState() => _AbstractViewWidgetState();
}
class _AbstractViewWidgetState extends State<AbstractViewWidget> {
  _AbstractViewWidgetState() : super();

  @override
  void initState(){
    super.initState();
    widget.initState();
    widget.model._updateView = _onUpdate;
  }

  @override
  void dispose(){
    widget.model._updateView = null;
    widget.dispose();
    super.dispose();
  }

  /// UI個別表現を更新するハンドラ。
  // ignore: missing_return
  UpdateView _onUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, widget.model);
  }
}


// ビルダー関数の引数 model がオプションになっていることに注意！
abstract class AbstractAnimationViewWidget<M extends AnimationViewModel> extends StatefulWidget {
  final M model;

  const AbstractAnimationViewWidget({
    Key key,
    @required this.model,
  }) : super(key: key);

  void initState(){}
  void dispose(){}

  /// アニメーション・コントローラ生成
  AnimationController onCreateController(TickerProvider vsync);

  /// アニメーション・オブジェクト生成
  List<Animation> onCreateAnimations(AnimationController controller);

  /// 子 UI表現構築用
  Widget onCreateChild(BuildContext context);

  /// アニメーションを伴なう、UI表現構築用
  Widget onAnimationBuild(BuildContext context, Widget child,
      AnimationController controller, List<Animation> animations, {M model});

  /// アニメーションを伴わない、UI表現構築用
  Widget noAnimationBuild(BuildContext context, Widget child, {M model});

  /// アニメーションリスト要素の型キャスト
  Animation<V> convertAnimation<V>(Animation<dynamic> animation) {
    return animation as Animation<V>;
  }

  @override
  _AbstractAnimationViewWidgetState createState() => _AbstractAnimationViewWidgetState();
}
class _AbstractAnimationViewWidgetState extends State<AbstractAnimationViewWidget>
    with TickerProviderStateMixin {
  Completer<bool> asyncUpdateCompleter;
  AnimationController controller;
  List<Animation> animations;
  _AbstractAnimationViewWidgetState() : super();

  @override
  void initState() {
    super.initState();
    widget.initState();
    widget.model._updateView = _onUpdate;
    widget.model._asyncUpdateView = _asyncUpdate;
    _initAnimation();
  }

  @override
  void dispose() {
    _disposeAnimation();
    widget.model._updateView = null;
    widget.model._asyncUpdateView = null;
    widget.dispose();
    super.dispose();
  }

  void _initAnimation() {
    controller = widget.onCreateController(this);
    animations = widget.onCreateAnimations(controller);
  }

  void _disposeAnimation() {
    controller?.stop();
    controller?.dispose();
    controller = null;
  }

  /// UI個別表現を更新するハンドラ。
  // ignore: missing_return
  UpdateView _onUpdate () {
    setState(() {});
  }

  Future<bool> _asyncUpdate() {
    setState(() {});
    asyncUpdateCompleter = Completer();
    return asyncUpdateCompleter.future;
  }

  @override
  Widget build(BuildContext context) {
    // アニメ実行済の場合は、再初期化を実行する。
    if (controller?.isCompleted ?? false) {
      _disposeAnimation();
      _initAnimation();
    }

    // trueになったときのみアニメを実行させます。
    if (widget.model.isAnimate) {
      final TransitionBuilder onBuilder = (BuildContext context, Widget child) {
        // 非同期更新の場合は、呼び出し元をアニメ完了後まで待機させるようにします。
        if (!(asyncUpdateCompleter?.isCompleted ?? true)) {
          if (controller.isCompleted) {
            asyncUpdateCompleter.complete(true);
          }
        }
        return widget.onAnimationBuild(
            context,
            child,
            controller,
            animations,
            model: widget.model);
      };
      return AnimatedBuilder(
          builder: onBuilder,
          animation: controller,
          child: widget.onCreateChild(context));

    } else {
      // 非同期更新の場合は、同期失敗で直帰させるようにします。
      if (!(asyncUpdateCompleter?.isCompleted ?? true)) {
        asyncUpdateCompleter.complete(false);
      }
      return widget.noAnimationBuild(
          context,
          widget.onCreateChild(context),
          model: widget.model);
    }
  }
}
