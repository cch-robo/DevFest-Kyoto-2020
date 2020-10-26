/*
BSD 3-Clause License

Copyright (c) 2020, cch-robo
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// アプリケーションの各ページ（画面）に、MVVM(Model-View-View Model)を提供するパッケージ。
// View は View Model に依存し、View Model は Model に依存する単方向の関係を導入します。
//
// - View は、バインド先の ViewModel からプロパティとコマンドが提供され、バインド先からの更新要求に応えます。
//   View Model は、バインド先の Model からプロパティとコマンドが提供され、バインド先からの更新要求に応えます。
//   Model は、ビジネスロジックとデータモデルを提供する、ドメインモデルを表し、ViewModel とバインドもできます。
//
// - View を表す ViewWidget と、View Model を表す ViewModel 基盤クラスを提供し、
//   View と View Model がバインドできるようにします。
//
// - Model を表す ViewModel 基盤クラスを提供し、
//   View Model と Model がバインドできるようにします。
//
// - ページ内の View Model や Model を一括管理するモデルコンテナ PageModelContainer と、
//   ページのUI表現の定義とモデルコンテナを指定するウィジェット PageWidget 基盤クラスを提供し、
//   PageWidget の build関数に追加された viewModels パラメータを介して、
//   モデルコンテナが公開する ViewModel がビルド定義内で利用できるようにします。
//
// - モデルコンテナ PageModelContainer は、
//   ページ内の View Model や Model の生成や初期設定の処理も一括管理しています。
//
// - アプリ内の Model を一括管理するモデルコンテナ AppModelContainer と、
//   アプリのモデルコンテナを指定するウィジェット AppWidget 基盤クラスも提供しています。
//   ページのモデルコンテナから、アプリのモデルコンテナを参照(*1)することで、
//   アプリ全体のビジネスロジックやデータモデルがページをまたいで利用できるようになります。
//   (*1) PageModelContainer#provideAppModelContainer<M>(BuildContext)
//
// 主要基盤クラス
// ・AppModelContainer：アプリ全体の Model を提供するモデルコンテナ
// ・PageModelContainer：ページ全体の ViewModel と Model を提供するモデルコンテナ
// ・Model：ビジネスロジックとデータモデルを提供する、ドメインモデルを表すクラス。（ViewModelとバインドもできる）
// ・ViewModel：View Model を表す、プロパティとコマンドを提供して View とバインドするクラス
// ・ViewWidget：View を表す、個別のUI表現を定義してバインド先の ViewModel を指定するウィジェット
// ・AnimationViewModel：アニメーションさせる個別のUI表現とバインドする ViewModel継承クラス
// ・AnimationViewWidget：アニメーションする個別のUI表現とバインド先を指定するウィジェット

import 'dart:async';

import 'package:flutter/material.dart';


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
///
/// - アプリ全体のルートウィジェット([AppWidget]継承オブジェクト)に管理される、<br/>
///   アプリ全体で利用される Model (ドメインモデルを表し、ビジネスロジックと<br/>
///   データモデルを含むクラス)を提供します。
/// - 継承先クラスでは、以下の処置を行ってください。<br/>
///   1.アプリ全体初期化処理([AppModelContainer.initModel])メソッドのオーバライド。<br/>
///   2.アプリ全体初期化処理([AppModelContainer.initApp])メソッドのオーバライド。<br/>
///   3.アプリ全体で管理する個別の Model を指定するフィールドの追加。<br/>
///   4.Model には、ドメインモデルを表す、ビジネスロジックとデータモデルを実装してください。
mixin AppModelContainer {
  /// アプリ全体で管理する Model の初期設定を行います。
  void initModel();

  /// アプリ全体に関わる初期設定を行います。
  void initApp(BuildContext context);
}

/// アプリ全体のウィジェット定義と<br/>
/// アプリ全体のモデルコンテナ([AppModelContainer]継承型オブジェクト)を指定する抽象基盤クラス。
///
/// - [AppWidget.build]メソッド引数の model で、<br/>
///   アプリ全体のモデルコンテナ([AppModelContainer]継承オブジェクト)を提供させるには、<br/>
///   [AppModelContainer.createModelContainer]メソッドをオーバーライドしてください。
/// - ジェネリクスで指定する [M] は、<br/>
///   利用するアプリ全体のモデルコンテナ([AppModelContainer])の継承型を表します。
abstract class AppWidget<M extends AppModelContainer> extends StatefulWidget {
  const AppWidget({
    Key key,
  }) : super(key: key);

  void initState(){}
  void dispose(){}

  /// AppModelContainer継承オブジェクト生成
  ///
  /// ```dart
  /// // 実装例
  /// @override
  /// MyAppModelContainer createModelContainer() {
  ///   return MyAppModelContainer();
  /// }
  /// ```
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
///
/// - ページ全体のUI表現([PageWidget]継承オブジェクト)に管理される、<br/>
///   ページ全体で利用される Model (ビジネスロジックとデータモデルを含むクラス)と<br/>
///   ViewModel (Viewにバインドされるプロパティとコマンドを提供するクラス)を提供します。
/// - 継承先クラスでは、以下の処置を行ってください。<br/>
///   1.ページ全体初期化処理([PageModelContainer.initModel])メソッドのオーバライド。<br/>
///   2.ページ全体初期化処理([PageModelContainer.initPage])メソッドのオーバライド。<br/>
///   3.ページ全体で管理する個別の Model と View Model を指定するフィールドの追加。<br/>
///   4.Model には、ビジネスロジックとデータモデルを実装してください。<br/>
///   5.View Model には、個別のUI表現に提供するプロパティとコマンドを実装してください。
///
/// ```dart
/// // 継承実装例
/// class SamplePageModelContainer with PageModelContainer {
///   SamplePageModelContainer(): super();
///
///   // 管理するモデルのフィールド
///   ViewModel<int> count;
///   Size pageSize;
///
///   // ページ全体管理モデル初期化処理オーバライド
///   @override
///   ViewModels initModel() {
///     count = ViewModel<int>(value:0);
///     return ViewModels([count], pageModel: this);
///   }
///
///   // ページ全体初期化処理オーバライド
///   @override
///   void initPage(BuildContext context) {
///     final MediaQueryData data = MediaQuery.of(context);
///     pageSize = data.size;
///     print('PageSize(${pageSize.width}, ${pageSize.height})');
///
///     final MyAppModelContainer appModelContainer = provideAppModel<MyAppModelContainer>(context);
///   }
/// }
/// ```
mixin PageModelContainer {
  /// ページ全体で公開する ViewModel 一覧
  ViewModels viewModels;

  /// ページ全体で管理するモデル値の初期設定を行います。
  ///
  /// ```dart
  /// // 実装例
  ///   @override
  ///   ViewModels initModel() {
  ///     count = ViewModel<int>(value:0);
  ///     return ViewModels([count]);
  ///   }
  /// ```
  ViewModels initModel();

  /// ページ全体に関わる初期設定を行います。
  ///
  /// ```dart
  /// // 実装例
  /// @override
  /// void initPage(BuildContext context) {
  ///   final MediaQueryData data = MediaQuery.of(context);
  ///   final Size pageSize = data.size;
  ///   print('PageSize(${pageSize.width}, ${pageSize.height})');
  ///
  ///   final MyAppModelContainer appModelContainer = provideAppModel<MyAppModelContainer>(context);
  /// }
  /// ```
  void initPage(BuildContext context);

  /// AppModelContainer継承オブジェクト提供
  M provideAppModelContainer<M extends AppModelContainer>(BuildContext context) {
    final AppWidgetState<M> state = context.findAncestorStateOfType<AppWidgetState<M>>();
    return state?.modelContainer;
  }
}

/// ページ全体のUI表現の定義と<br/>
/// ページ全体のモデルコンテナ([PageModelContainer]継承型オブジェクト)を指定する抽象基盤クラス。
///
/// - [PageWidget.build]メソッド引数の viewModels で、<br/>
///   ページ全体で公開する ViewModel 一覧([ViewModels]オブジェクト)を提供させるには、<br/>
///   [PageWidget.createModelContainer]メソッドをオーバーライドしてください。
/// - ジェネリクスで指定する [M] は、<br/>
///   利用するページ全体のモデルコンテナ([PageModelContainer])の継承型を表します。
abstract class PageWidget<M extends PageModelContainer> extends StatefulWidget {
  const PageWidget({
    Key key,
  }) : super(key: key);

  void initState(){}
  void dispose(){}

  /// PageModelContainer継承オブジェクト生成
  ///
  /// ```dart
  /// // 実装例
  /// @override
  /// MyHomeModelContainer createModelContainer() {
  ///   return MyHomeModelContainer();
  /// }
  /// ```
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
///
/// - 個別のUI表現([ViewWidget])で利用されるプロパティやコマンドを提供します。<br/>
///   継承先で、個別のUI表現に必要になるフィールドやロジックを独自追加してください。
/// - [value]フィールドで、オプションの値モデル([T]型のオブジェクト)を提供します。
/// - [updateView]メソッドで、バインド先の個別のUI表現([ViewWidget])を更新描画します。
/// - 他の Model や View Model と連携する必要がある場合は、<br/>
///   コンストラクタ引数で、連携先オブジェクトを受け取るようにしてください。
/// - ジェネリクスで指定する [T] は、オプションで提供する値モデルの型を表します。
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
///
/// - 個別のUI表現([AnimationViewModel])で利用されるプロパティやコマンドを提供します。<br/>
///   継承先で、個別のUI表現に必要になるフィールドやロジックを独自追加してください。
/// - [isAnimate]フィールドで、アニメーション(ON/OFF)の状態を提供します。
/// - [value]フィールドで、オプションの値モデル([T]型のオブジェクト)を提供します。
/// - [updateView]メソッドで、バインド先の個別のUI表現([AnimationViewModel])を更新描画します。
/// - [asyncUpdateView]メソッドで、アニメーション完了まで待機する更新描画を行います。
/// - 他の Model や View Model と連携する必要がある場合は、<br/>
///   コンストラクタ引数で、連携先オブジェクトを受け取るようにしてください。
/// - ジェネリクスで指定する [T] は、オプションで提供する値モデルの型を表します。
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

  /// 指定 ViewModel一覧を追加した、新しい ViewModel一覧を作成
  ViewModels addAll(List<ViewModel> viewModels) {
    final List<ViewModel> newViewModels = <ViewModel>[];
    newViewModels.addAll(_viewModels ?? <ViewModel>[]);
    newViewModels.addAll(viewModels ?? <ViewModel>[]);
    return ViewModels(newViewModels, _pageModelContainer);
  }

  /// 指定 ViewModel型 の ViewModel要素インデックス取得
  int _indexOf<T extends ViewModel>() {
    int index = (_viewModels?.length ?? 0) - 1;
    for(; index > -1; index--) {
      if (_viewModels[index].runtimeType == T) {
        break;
      } else {
        continue;
      }
    }
    return index;
  }

  /// 指定 ViewModel型 の ViewModel要素置換
  T replace<T extends ViewModel>(T object) {
    final int index = _indexOf<T>();
    if (index == -1) {
      return null;
    }
    _viewModels.removeAt(index);
    _viewModels.insert(index, object);
    _viewModelMap[T] = object;
    return find<T>();
  }

  /// 指定 index の ViewModel要素取得
  T get<T extends ViewModel>(int index) {
    if (_viewModels == null || _viewModels.isEmpty) {
      return null;
    }
    return _viewModels[index] as T;
  }

  /// 指定 ViewModel型 の ViewModel要素取得
  T find<T extends ViewModel>() {
    return _viewModelMap[T] as T;
  }

  static Map<Type,ViewModel> _parseMap(List<ViewModel> models) {
    final Map<Type,ViewModel> viewModelMap = {};
    if (models != null && models.isNotEmpty) {
      for(ViewModel model in models) {
        final Type type = model.runtimeType;
        viewModelMap[type] = model;
      }
    }
    return viewModelMap;
  }
}

/// ページ内の個別のUI表現の定義と利用する View Model([ViewModel])を指定する基盤クラス。
///
/// - コンストラクタ引数[model]で、利用する View Model([ViewModel]オブジェクト)を指定します。
/// - コンストラクタ引数[builder]で、[ViewBuilder]に従った個別のUI表現ビルドを定義します。
/// - UI表現更新時は、[builder]の第2引数 model に、[model]の最新の View Model オブジェクトが入ります。
/// - ジェネリクスで指定する [T] は、利用する値モデルの型を表します。
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
  ///
  /// - AnimationController オブジェクトを生成してください。
  ///
  /// ```dart
  /// // 実装例
  /// @override
  /// AnimationController onCreateController(TickerProvider vsync) {
  ///   return AnimationController(
  ///       duration: const Duration(milliseconds: 500),
  ///       vsync: vsync)..forward();
  /// }
  /// ```
  AnimationController onCreateController(TickerProvider vsync);

  /// アニメーション・オブジェクト生成
  ///
  /// - AnimationController を元に、<br/>
  ///   変化するプロパティ値を提供する Animation オブジェクトを独自生成してください。
  /// - 独自生成した Animation オブジェクトを保持させるフィールドを追加してください。
  ///
  /// ```dart
  /// // 実装例
  /// @override
  /// List<Animation> onCreateAnimations(AnimationController controller) {
  ///   animation = Tween<double>(begin: 1.0, end: 0.0).animate(controller);
  ///   return <Animation>[animation];
  /// }
  ///
  /// // 独自追加フィールド
  /// Animation<double> animation;
  /// ```
  List<Animation> onCreateAnimations(AnimationController controller);

  /// 子 UI表現構築用
  ///
  /// - ビルド関数に提供する、子 UI表現(child引数)を定義します。<br/>
  ///   定義内容は、[onAnimationBuild] や [noAnimationBuild] の第2引数 child に提供されます。
  /// - 実装では、AnimationController や Animation オブジェクトは使わないでください。
  Widget onCreateChild(BuildContext context);

  /// アニメーションを伴なう、UI表現構築用
  ///
  /// - [isAnimate]が true時の UI表現構築に利用されるビルド関数です。
  /// - AnimationController オブジェクトが有効です。
  /// - 独自に定義した Animation オブジェクトを利用することができます。
  Widget onAnimationBuild(BuildContext context, Widget child,
      AnimationController controller, List<Animation> animations, {M model});

  /// アニメーションを伴わない、UI表現構築用
  ///
  /// - [isAnimate]が false時の UI表現構築に利用されるビルド関数です。
  /// - AnimationController や Animation オブジェクトは使えません。<br/>
  ///   （いずれも null ではありませんが、利用しても意味がありません。）
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
