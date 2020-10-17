import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:memojudge/src/library/model_view_viewmodel_container.dart';

/// step game
void startApp() {
  runApp(MemoJudgeApp());
}

/// アプリ全体のモデル（モデル/ビジネスロジックとデータ）を提供するモデルコンテナ
class GameAppModelContainer with AppModelContainer {
  GameAppModelContainer() : super();

  /// ゲーム状態のモデル
  GameStateModel gameState;

  @override
  void initModel() {
    gameState = GameStateModel();
  }

  @override
  void initApp(BuildContext context) {
  }
}

/// TapButtonがタップされたことを通知する関数型
typedef TapButtonNotify = void Function(int);

/// ページ全体のモデル（ビューモデルとモデル）を提供するモデルコンテナ
class GameModelContainer with PageModelContainer {

  /// ゲームロジックのモデル
  GamePlayModel gamePlay;

  /// デモ表示のビューモデル
  DemosViewModel isOnDemos;

  /// タップ入力バリアのビューモデル
  TapBlockViewModel isTapBlock;

  /// タップボタン・コンテナのビューモデル
  TapButtonsAnimationViewModel tapButtonsContainer;

  /// LEVEL 表示のビューモデル
  LevelAnimationViewModel level;

  /// CHALLENGE 表示のビューモデル
  ChallengeAnimationViewModel challenge;

  /// CLEAR 表示のビューモデル
  ClearAnimationViewModel clear;

  /// MISS 表示のビューモデル
  MissAnimationViewModel miss;

  /// TIMEUP 表示のビューモデル
  TimeUpAnimationViewModel timeUp;

  /// REPLAY 表示のビューモデル
  ReplayAnimationViewModel replay;

  /// GAME OVER 表示のビューモデル
  GameOverAnimationViewModel gameOver;

  /// HIGH SCORE 表示のビューモデル
  HighScoreAnimationViewModel highScore;

  @override
  ViewModels initModel() {
    gamePlay = GamePlayModel();

    isOnDemos  = DemosViewModel(gamePlay.isOnDemos, gamePlay.stopDemos);
    isTapBlock = TapBlockViewModel(gamePlay.isTapBlock);

    level = LevelAnimationViewModel(gamePlay.level);
    challenge = ChallengeAnimationViewModel(gamePlay.challenge);
    clear = ClearAnimationViewModel(gamePlay.clear);
    miss = MissAnimationViewModel(gamePlay.miss);
    timeUp = TimeUpAnimationViewModel(gamePlay.timeUp);
    replay = ReplayAnimationViewModel(gamePlay.replay);
    gameOver = GameOverAnimationViewModel(gamePlay.gameOver);
    highScore = HighScoreAnimationViewModel(gamePlay.highScore);
    tapButtonsContainer = TapButtonsAnimationViewModel(
        <TapButtonAnimationViewModel>[
          TapButtonAnimationViewModel(gamePlay.tapButtons[0].showModel, 0, gamePlay.tapNotify),
          TapButtonAnimationViewModel(gamePlay.tapButtons[1].showModel, 1, gamePlay.tapNotify),
          TapButtonAnimationViewModel(gamePlay.tapButtons[2].showModel, 2, gamePlay.tapNotify),
          TapButtonAnimationViewModel(gamePlay.tapButtons[3].showModel, 3, gamePlay.tapNotify),
          TapButtonAnimationViewModel(gamePlay.tapButtons[4].showModel, 4, gamePlay.tapNotify),
          TapButtonAnimationViewModel(gamePlay.tapButtons[5].showModel, 5, gamePlay.tapNotify),
        ]
    );

    return ViewModels([
      isOnDemos,
      isTapBlock,
      tapButtonsContainer,
      level,
      challenge,
      clear,
      miss,
      timeUp,
      replay,
      gameOver,
      highScore,
    ], this);
  }

  @override
  void initPage(BuildContext context) {
    // GameAppModelContainer から、GameState オブジェクトを提供してもらう。
    gamePlay.gameState = provideAppModelContainer<GameAppModelContainer>(context).gameState;
    gamePlay.start();
  }
}

/// ゲーム状態のモデル
class GameStateModel {
  GameStateModel();

  /// ゲーム起動済フラグ（二重起動抑止用）
  bool isStarting = false;

  /// ハイスコア
  int highScore = 0;
}

/// ゲーム板のモデル
class GameStageModel {
  GameStageModel(
      BuildContext context,
  ) : stageSize = _computeGameStageSize(context),
      fontSize = _computeFontSize(_computeGameStageSize(context)) {
    print('PageSize(${stageSize.width}, ${stageSize.height}), '
        'GameFieldSize(${stageSize.width}, ${stageSize.height}), '
        'fontSize=$fontSize');
  }

  /// ゲーム板の縦×横サイズ
  final Size stageSize;

  /// ゲーム板の文字サイズ
  final double fontSize;

  /// 現在のページ高さで、横２列と縦３行が配置できる幅を持つ、ゲーム板サイズを返す。
  static Size _computeGameStageSize(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    final Size pageSize = data.size;
    final double height = pageSize.height;
    double width = (pageSize.width > height) ? height : pageSize.width;
    width = (width / 2 > height / 3) ? height / 3 * 2 : width;
    return Size(width, height);
  }

  /// 現在のゲーム板サイズからフォントサイズを計算する。
  static double _computeFontSize(Size stageSize) {
    final double fontSize = stageSize.width / 10;
    return fontSize;
  }
}

/// ゲームプレイのモデル
class GamePlayModel {
  GamePlayModel() {
    _random = Random.secure();
    _tapButtons = [
      OperationShowModel(false),
      OperationShowModel(false),
      OperationShowModel(false),
      OperationShowModel(false),
      OperationShowModel(false),
      OperationShowModel(false),
    ];
    _tapQuestions = <int>[];
    _tapAnswers = <int>[];
    _tapScore = 0;
    _tapChallengeTimer = null;
    _tapNotify = tapNotifyHandler;
  }

  /// （公開プロパティ）ゲーム状態モデル
  set gameState (GameStateModel state) => _gameState = state;

  /// （公開コマンド）デモ停止
  VoidFunction get stopDemos => _stopDemos;

  /// （公開コマンド）タップ通知コマンド
  TapButtonNotify get tapNotify => _tapNotify;

  /// （公開プロパティ）タップボタン・コレクション
  List<OperationShowModel> get tapButtons => _tapButtons;

  /// （公開プロパティ）デモ表示フラグ
  ShowModel get isOnDemos => _isOnDemos.showModel;

  /// （公開プロパティ）タップ入力ブロックフラグ
  ShowModel get isTapBlock => _isTapBlock.showModel;

  /// （公開プロパティ）レベル表示フラグ
  ShowModel get level => _level.showModel;

  /// （公開プロパティ）チャレンジ表示フラグ
  ShowModel get challenge => _challenge.showModel;

  /// （公開プロパティ）クリア表示フラグ
  ShowModel get clear => _clear.showModel;

  /// （公開プロパティ）ミス表示フラグ
  ShowModel get miss => _miss.showModel;

  /// （公開プロパティ）タイムアップ表示フラグ
  ShowModel get timeUp => _timeUp.showModel;

  /// （公開プロパティ）リプレイ表示フラグ
  ShowModel get replay => _replay.showModel;

  /// （公開プロパティ）ゲームオーバー表示フラグ
  ShowModel get gameOver => _gameOver.showModel;

  /// （公開プロパティ）ハイスコア表示フラグ
  ShowModel get highScore => _highScore.showModel;

  /// （公開コマンド）ゲーム起動
  void start() {
    if (!_gameState.isStarting) {
      _gameState.isStarting = true;
      // ページ表示と異なる Isolate で、デモ表示開始
      Future(() {
        _startDemos();
      });
    }
  }

  //＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊
  // 以降は、モデル内部の非公開なプロパティとロジックです。
  //＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊

  /// ゲーム状態のモデル
  GameStateModel _gameState;

  // ＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊
  // ゲームプレイの状態要素
  // ＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊

  /// 乱数生成器
  Random _random;

  /// タップ通知コマンド
  TapButtonNotify _tapNotify;

  /// タップボタン・コレクション
  List<OperationShowModel> _tapButtons;

  /// タップ順問題リスト
  List<int> _tapQuestions;

  /// タップ順解答リスト
  List<int> _tapAnswers;

  /// タップスコア（レベル）
  int _tapScore;

  /// タップチャレンジ・タイムアップタイマー
  Timer _tapChallengeTimer;

  /// デモ表示フラグ
  final OperationShowModel _isOnDemos = OperationShowModel(false);

  /// タップ入力バリア(ON/OFF)フラグ
  final OperationShowModel _isTapBlock = OperationShowModel(false);

  /// LEVEL 表示フラグ
  final OperationShowModel _level = OperationShowModel(false, 0);

  /// CHALLENGE 表示フラグ
  final OperationShowModel _challenge = OperationShowModel(false);

  /// CLEAR 表示フラグ
  final OperationShowModel _clear = OperationShowModel(false);

  /// MISS 表示フラグ
  final OperationShowModel _miss = OperationShowModel(false);

  /// TIMEUP 表示フラグ
  final OperationShowModel _timeUp = OperationShowModel(false);

  /// REPLAY 表示フラグ
  final OperationShowModel _replay = OperationShowModel(false);

  /// GAME OVER 表示フラグ
  final OperationShowModel _gameOver = OperationShowModel(false);

  /// HIGH SCORE 表示フラグ
  final OperationShowModel _highScore = OperationShowModel(false, 0);


  /// デモ表示を行う。
  Future<void> _startDemos() async {
    print('DEMOS');
    _isOnDemos.set(true);
    _isTapBlock.set(true);

    // デモ中フラグが変更されるまで、１秒毎にランダムタップを繰り返す。
    while(_isOnDemos.isShow) {
      final int index = _random.nextInt(_tapButtons.length);
      _tapButtons[index].set(true);
      await _asyncWait(1000);
      _tapButtons[index].set(false);
    }

    // ゲーム開始
    _startTapChallenge();
  }

  // デモ表示を中止させる。
  void _stopDemos() {
    _isOnDemos.set(false);
  }

  /// タップ順記憶ゲーム開始
  void _startTapChallenge() {
    _isTapBlock.set(true);
    _tapScore = 0;
    _nextTapChallenge();
  }

  /// レベルアップ・チャレンジ開始
  Future<void> _nextTapChallenge() async {
    // レベルアップしたタップ順設問作成
    _tapScore++;
    _tapAnswers.clear();
    _tapQuestions.clear();
    for (int i = 0; i < _tapScore; i++) {
      final int index = _random.nextInt(tapButtons.length);
      _tapQuestions.add(index);
    }

    // 出題
    print('LEVEL  $_tapScore');
    _level.set(true, _tapScore);
    await _asyncWait(2000);
    await _tapTrace(_tapQuestions);
    _level.set(false);

    // チャレンジ開始（入力待ちに切替）
    print('CHALLENGE');
    _challenge.set(true);
    await _asyncWait(1000);
    _isTapBlock.set(false);
    _challenge.set(false);
    _setupChallengeTimer(true);
  }

  /// チャレンジタイマー設定
  void _setupChallengeTimer(bool isCreate) {
    if (isCreate) {
      _tapChallengeTimer = Timer(
          Duration(seconds: _tapScore * 2),
          _tapsTimeUp);
    } else {
      _tapChallengeTimer.cancel();
    }
  }

  /// TapButtonタップ通知ハンドラ
  void tapNotifyHandler(int tapIndex) {
    print('TapButton[$tapIndex] is tapped!');
    _tapAnswers.add(tapIndex);
    _checkTapAnswer(tapIndex);
  }

  // チャレンジ正解チェック
  Future<void> _checkTapAnswer(int tapIndex) async {
    /// 正解チェック
    final int count = _tapAnswers.length;
    if (_tapQuestions[count - 1] == tapIndex) {
      print('OK');

    } else {
      await _tapsMistake();
      return;
    }

    /// チャレンジ完了判定
    if (_tapQuestions.length == count) {
      _setupChallengeTimer(false);
      _isTapBlock.set(true);

      print('CLEAR');
      _clear.set(true);
      await _asyncWait(2000);
      _clear.set(false);

      // 次チャレンジ
      _nextTapChallenge();
    }
  }

  /// タップミス処置
  Future<void> _tapsMistake() async {
    _setupChallengeTimer(false);
    _isTapBlock.set(true);

    print('MISS');
    _miss.set(true);
    await _asyncWait(2000);
    _miss.set(false);

    await _failed();
  }

  /// タイムアップ処置
  Future<void> _tapsTimeUp() async {
    _isTapBlock.set(true);

    print('TIME UP');
    _timeUp.set(true);
    await _asyncWait(2000);
    _timeUp.set(false);

    await _failed();
  }

  /// チャレンジ失敗処置
  Future<void> _failed() async {
    // 正解リプレイ
    print('REPLAY');
    _replay.set(true);
    await _tapTrace(_tapQuestions);
    _replay.set(false);

    // ゲームオーバー
    print('GAME OVER');
    _gameOver.set(true);
    await _asyncWait(5000);
    _gameOver.set(false);

    // ハイスコア判定
    final int score = _tapScore - 1;
    if (score > _gameState.highScore) {
      print('HIGH SCORE ($score)');
      _gameState.highScore = score;
      _highScore.set(true, score);
      await _asyncWait(10000);
      _highScore.set(false);
    }

    // デモ表示をタップとは別の Isolate で実行させます。
    Future(() => _startDemos());
  }

  /// TapButtonタップ順トレース
  Future<void> _tapTrace(List<int> tapOrders) {
    final Completer completer = Completer();
    final int lastIndex = tapOrders.length;
    int historyIndex = 0;
    Timer.periodic(
      const Duration(seconds: 1),
          (Timer timer) {
        if (historyIndex != lastIndex) {
          // タップ表現を再現する。
          final int index = tapOrders[historyIndex++];
          _tapButtons[index].set(true);
          print('trace tapping TapButton[$index]');
        } else {
          // タイマーの時間ごとの繰り返し(periodic)を終了する。
          timer.cancel();
          completer.complete();
        }
      },
    );
    return completer.future;
  }

  /// 処理を指定時間待機させる。（遅延非同期処理を利用）
  Future<void> _asyncWait(int milliseconds) {
    final Future<void> future = Future.delayed(
      Duration(milliseconds: milliseconds),
          () {},
    );
    return future;
  }
}

/// 表示ON/OFFフラグ＆値操作を提供するモデル (read/write)
class OperationShowModel {
  OperationShowModel(this._isShow, [this._value = 0]) {
    _showModel = ShowModel(this);
  }

  bool _isShow;
  int _value;
  ShowModel _showModel;

  bool get isShow => _isShow;
  int  get value => _value;
  ShowModel get showModel => _showModel;

  /// 状態を更新する
  void set(bool isShow, [int value]) {
    _isShow = isShow;
    if (value != null) {
      _value = value;
    }
    _showModel.updateViewModels();
  }
}

/// 表示ON/OFFフラグ＆値参照を提供するモデル (read only)
class ShowModel extends Model {
  final OperationShowModel _model;
  ShowModel(this._model);
  bool get isShow => _model.isShow;
  int get value => _model.value;
}

/// 表示ON/OFFフラグを提供するビューモデル基盤
class _FlagViewModel extends ViewModel<bool> {
  final ShowModel _model;
  _FlagViewModel(this._model) : super(value: _model.isShow) {
    _model.bindUpdate(onUpdate);
  }

  @override
  void onUpdate(Model model) {
    if (model?.hashCode == _model.hashCode ?? false) {
      value = _model.isShow;
      updateView();
    }
  }
}

/// デモ表示(表示ON/OFF付き)のビューモデル
class DemosViewModel extends _FlagViewModel {
  final VoidFunction stopDemos;
  DemosViewModel(ShowModel model, this.stopDemos) : super(model);
  bool get isOnDemos => value;
}

/// タップ入力バリア(表示ON/OFF付き)のビューモデル
class TapBlockViewModel extends _FlagViewModel {
  TapBlockViewModel(ShowModel model) : super(model);
  bool get isTapBlock => value;
}

/// タップボタン・ビューモデルのコンテナ
class TapButtonsAnimationViewModel extends ViewModel {
  final List<TapButtonAnimationViewModel> _tapButtons;
  TapButtonsAnimationViewModel(this._tapButtons) : super();
  List<TapButtonAnimationViewModel> get tapButtons => _tapButtons;
}

/// アニメ表示ON/OFFフラグを提供するビューモデル基盤
class _FlagAnimationViewModel extends AnimationViewModel {
  final ShowModel _model;
  _FlagAnimationViewModel(this._model) : super(isAnimate: _model.isShow) {
    _model.bindUpdate(onUpdate);
  }

  @override
  Future<void> onUpdate(Model model) async {
    if (model?.hashCode == _model.hashCode ?? false) {
      isAnimate = _model.isShow;
      await asyncUpdateView();
    }
  }
}

/// タップボタン表示(アニメ表示ON/OFF付き)のビューモデル
class TapButtonAnimationViewModel extends _FlagAnimationViewModel {
  final int index;
  final TapButtonNotify notify;
  TapButtonAnimationViewModel(ShowModel model, this.index, this.notify) : super(model);
}

/// チャレンジ表示(アニメ表示ON/OFF付き)のビューモデル
class ChallengeAnimationViewModel extends _FlagAnimationViewModel {
  ChallengeAnimationViewModel(ShowModel model) : super(model);
}

/// チャレンジクリア表示(アニメ表示ON/OFF付き)のビューモデル
class ClearAnimationViewModel extends _FlagAnimationViewModel {
  ClearAnimationViewModel(ShowModel model) : super(model);
}

/// ミス表示(アニメ表示ON/OFF付き)のビューモデル
class MissAnimationViewModel extends _FlagAnimationViewModel {
  MissAnimationViewModel(ShowModel model) : super(model);
}

/// タイムアップ表示(アニメ表示ON/OFF付き)のビューモデル
class TimeUpAnimationViewModel extends _FlagAnimationViewModel {
  TimeUpAnimationViewModel(ShowModel model) : super(model);
}

/// リプレイ表示(アニメ表示ON/OFF付き)のビューモデル
class ReplayAnimationViewModel extends _FlagAnimationViewModel {
  ReplayAnimationViewModel(ShowModel model) : super(model);
}

/// ゲームオーバー表示(アニメ表示ON/OFF付き)のビューモデル
class GameOverAnimationViewModel extends _FlagAnimationViewModel {
  GameOverAnimationViewModel(ShowModel model) : super(model);
}

/// int プロパティ付きアニメON/OFFフラグを提供するビューモデル基盤
class _IntWithAnimationViewModel extends AnimationViewModel<int> {
  final ShowModel _model;
  _IntWithAnimationViewModel(this._model)
      : super(isAnimate: _model.isShow, value: _model.value) {
    _model.bindUpdate(onUpdate);
  }

  @override
  Future<void> onUpdate(Model model) async {
    if (model?.hashCode == _model.hashCode ?? false) {
      if (_model.value != null) {
        value = _model.value;
      }
      isAnimate = _model.isShow;
      await asyncUpdateView();
    }
  }
}

/// レベル表示(intプロパティ＋アニメ表示ON/OFF付き)のビューモデル
class LevelAnimationViewModel extends _IntWithAnimationViewModel {
  LevelAnimationViewModel(ShowModel model) : super(model);
}

/// ハイスコア表示(intプロパティ＋アニメ表示ON/OFF付き)のビューモデル
class HighScoreAnimationViewModel extends _IntWithAnimationViewModel {
  HighScoreAnimationViewModel(ShowModel model) : super(model);
}


/// ゲームのアプリウィジェット
class MemoJudgeApp extends AppWidget<GameAppModelContainer> {
  @override
  GameAppModelContainer createModelContainer() {
    return GameAppModelContainer();
  }

  @override
  Widget build(BuildContext context, GameAppModelContainer modelContainer) {
    return MaterialApp(
      title: 'Memory Judge',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GameFieldPage(),
    );
  }
}

/// ゲームのページウィジェット
class GameFieldPage extends PageWidget<GameModelContainer> {
  const GameFieldPage({
        Key key,
      }) : super(key: key);

  @override
  GameModelContainer createModelContainer() {
    return GameModelContainer();
  }

  @override
  Widget build(BuildContext context, ViewModels viewModels) {
    final GameStageModel stage = GameStageModel(context);
    return Material(
      child: Stack(
        fit:StackFit.loose,
        children: [
          Center(child: Container(
              width: stage.stageSize.width,
              height: stage.stageSize.height,
              color: Colors.black26,
              child: Center(child: GridView.count(
                  primary: false,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20),
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  crossAxisCount: 2,
                  children: <Widget>[
                    TapButtonAnimationWidget(
                        model: viewModels.find<TapButtonsAnimationViewModel>().tapButtons[0],
                        color: Colors.blue),
                    TapButtonAnimationWidget(
                        model: viewModels.find<TapButtonsAnimationViewModel>().tapButtons[1],
                        color: Colors.red),
                    TapButtonAnimationWidget(
                        model: viewModels.find<TapButtonsAnimationViewModel>().tapButtons[2],
                        color: Colors.green),
                    TapButtonAnimationWidget(
                        model: viewModels.find<TapButtonsAnimationViewModel>().tapButtons[3],
                        color: Colors.purple),
                    TapButtonAnimationWidget(
                        model: viewModels.find<TapButtonsAnimationViewModel>().tapButtons[4],
                        color: Colors.yellow),
                    TapButtonAnimationWidget(
                        model: viewModels.find<TapButtonsAnimationViewModel>().tapButtons[5],
                        color: Colors.orange),
                  ],
                ),
              ),
            ),
          ),
          LevelAnimationWidget(model: viewModels.find<LevelAnimationViewModel>(), fontSize: stage.fontSize),
          ChallengeAnimationWidget(model: viewModels.find<ChallengeAnimationViewModel>(), fontSize: stage.fontSize),
          ClearAnimationWidget(model: viewModels.find<ClearAnimationViewModel>(), fontSize: stage.fontSize),
          MissAnimationWidget(model: viewModels.find<MissAnimationViewModel>(), fontSize: stage.fontSize),
          TimeUpAnimationWidget(model: viewModels.find<TimeUpAnimationViewModel>(), fontSize: stage.fontSize),
          ReplayAnimationWidget(model: viewModels.find<ReplayAnimationViewModel>(), fontSize: stage.fontSize),
          GameOverAnimationWidget(model: viewModels.find<GameOverAnimationViewModel>(), fontSize: stage.fontSize),
          HighScoreAnimationWidget(model: viewModels.find<HighScoreAnimationViewModel>(), fontSize: stage.fontSize),
          TapBlockViewWidget(isTapBlock: viewModels.find<TapBlockViewModel>()),
          DemosViewWidget(demos: viewModels.find<DemosViewModel>(), fontSize: stage.fontSize * 0.9)
        ],
      ),
    );
  }
}


/// 縁取り付きのテキストを表示するビューウィジェット
class BorderText extends StatelessWidget {
  // This custom text widget is based on the Stack Overflow post below.
  // How to decorate text stroke in Flutter?
  // https://stackoverflow.com/questions/52146269/how-to-decorate-text-stroke-in-flutter

  const BorderText(this.text, {
    Key key,
    @required this.color,
    @required this.borderColor,
    @required this.borderWidth,
    this.fontSize,
    this.fontStyle,
    this.fontWeight,
  }) : _scale = (borderWidth * 2 + fontSize) / fontSize, super(key: key);

  final String text;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double fontSize;
  final double _scale;
  final FontStyle fontStyle;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(text,
          style: TextStyle(
              fontSize: fontSize ?? 14.0,
              color: color,
              fontStyle: fontStyle,
              fontWeight: fontWeight,
              shadows: [
                Shadow(
                    offset: Offset(-_scale, -_scale),
                    color: borderColor
                ),
                Shadow(
                    offset: Offset(_scale, -_scale),
                    color: borderColor
                ),
                Shadow(
                    offset: Offset(-_scale, _scale),
                    color: borderColor
                ),
                Shadow(
                    offset: Offset(_scale, _scale),
                    color: borderColor
                ),
              ],
          ));
  }
}


/// タップ入力をブロックするためのビューウィジェット
class TapBlockViewWidget extends AbstractViewWidget<TapBlockViewModel> {
  const TapBlockViewWidget({
    Key key,
    @required TapBlockViewModel isTapBlock,
  }) : super(key:key, model: isTapBlock);

  @override
  Widget build(BuildContext context, ViewModel<bool> model) {
    return model.value
        ? Container(color: Colors.transparent)
        : const SizedBox.shrink();
  }
}

/// デモ表示中にゲーム説明をオーバラップ表示するビューウィジェット
class DemosViewWidget extends AbstractViewWidget<DemosViewModel> {
  final double fontSize;
  const DemosViewWidget({
    Key key,
    @required DemosViewModel demos,
    @required this.fontSize,
  }) : super(key:key, model: demos);

  @override
  Widget build(BuildContext context, DemosViewModel model) {
    return model.value
        ? Align(
            alignment: Alignment.center,
            child: TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                overlayColor: MaterialStateProperty.all<Color>(Colors.transparent),
                shadowColor: MaterialStateProperty.all<Color>(Colors.transparent),
              ),
              onPressed: model.stopDemos,
              child: BorderText(
                'Memorize the order of \n'
                'the glowing buttons\n'
                'and tap them in order.\n\n'
                'Tap to start the game.',

                fontSize: fontSize,
                color: Colors.white,
                borderColor: Colors.black,
                borderWidth: fontSize/5,
              ),
            ),
          ) // This trailing comma makes auto-formatting nicer for build methods.
        : const SizedBox.shrink();
  }
}


/// せり上がるラベル・アニメーション表示と非表示の UI表示を適用するビューウィジェット基盤
/// (ビューモデルが、アニメーション表示ON/OFFだけでなく intプロパティを持つ場合、ラベルの末尾に数値を追加します。)
class RiseUpAnimationWidget<T extends AnimationViewModel> extends AbstractAnimationViewWidget<T> {
  final String label;
  final Color fontColor;
  final double fontSize;

  const RiseUpAnimationWidget({
    Key key,
    @required T model,
    @required this.label,
    @required this.fontColor,
    this.fontSize,
  }) : super(key: key, model: model);

  @override
  AnimationController onCreateController(TickerProvider vsync) {
    return AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: vsync)..forward();
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
      AnimationController controller, List<Animation> animations, {T model}) {
    // value が null でない場合は、label に続いて値を表示します。
    //
    // Alignment は、左端/上端が-1.0 で 右端/下端が 1.0 の位置を表す座標系なので、
    // Alignmentの x は、0.0 ⇒ 中央固定で、y を 1.0 〜 0.0 まで変化させて、
    // 画面下端から中央に移動させます。
    final Animation<double> animation = convertAnimation(animations[0]);
    return Align(
      alignment: Alignment(0.0, animation.value),
      widthFactor : null,
      heightFactor : null,
      child: BorderText('$label${model.value == null ? "" : " ${model.value}"}',
        fontSize: fontSize,
        color: fontColor,
        borderColor: Colors.black,
        borderWidth: fontSize / 5,
      ),
    );
  }

  @override
  Widget noAnimationBuild(BuildContext context, Widget child, {T model}) {
    return const SizedBox.shrink();
  }
}

/// レベル表示をオーバラップしながらアニメーション表示するビューウィジェット
class LevelAnimationWidget extends RiseUpAnimationWidget<LevelAnimationViewModel> {
  const LevelAnimationWidget({
    Key key,
    @required LevelAnimationViewModel model,
    @required double fontSize,
  }) : super(
        key: key, model: model,
        label: 'LEVEL', fontColor: Colors.green, fontSize: fontSize);
}

/// チャレンジ表示をオーバラップしながらアニメーション表示するビューウィジェット
class ChallengeAnimationWidget extends RiseUpAnimationWidget<ChallengeAnimationViewModel> {
  const ChallengeAnimationWidget({
    Key key,
    @required ChallengeAnimationViewModel model,
    @required double fontSize,
  }) : super(
        key: key, model: model,
        label: 'CHALLENGE', fontColor: Colors.orange, fontSize: fontSize);
}

/// チャレンジクリア表示をオーバラップしながらアニメーション表示するビューウィジェット
class ClearAnimationWidget extends RiseUpAnimationWidget<ClearAnimationViewModel> {
  const ClearAnimationWidget({
    Key key,
    @required ClearAnimationViewModel model,
    @required double fontSize,
  }) : super(
      key: key, model: model,
      label: 'CLEAR', fontColor: Colors.white, fontSize: fontSize);
}

/// ミス表示をオーバラップしながらアニメーション表示するビューウィジェット
class MissAnimationWidget extends RiseUpAnimationWidget<MissAnimationViewModel> {
  const MissAnimationWidget({
    Key key,
    @required MissAnimationViewModel model,
    @required double fontSize,
  }) : super(
        key: key, model: model,
        label: 'MISS', fontColor: Colors.yellow, fontSize: fontSize);
}

/// タイムアップ表示をオーバラップしながらアニメーション表示するビューウィジェット
class TimeUpAnimationWidget extends RiseUpAnimationWidget<TimeUpAnimationViewModel> {
  const TimeUpAnimationWidget({
    Key key,
    @required TimeUpAnimationViewModel model,
    @required double fontSize,
  }) : super(
      key: key, model: model,
      label: 'TIME UP', fontColor: Colors.yellow, fontSize: fontSize);
}

/// リプレイ表示をオーバラップしながらアニメーション表示するビューウィジェット
class ReplayAnimationWidget extends RiseUpAnimationWidget<ReplayAnimationViewModel> {
  const ReplayAnimationWidget({
    Key key,
    @required ReplayAnimationViewModel model,
    @required double fontSize,
  }) : super(
        key: key, model: model,
        label: 'REPLAY', fontColor: Colors.cyan, fontSize: fontSize);
}

/// ゲームオーバー表示をオーバラップしながらアニメーション表示するビューウィジェット
class GameOverAnimationWidget extends RiseUpAnimationWidget<GameOverAnimationViewModel> {
  const GameOverAnimationWidget({
    Key key,
    @required GameOverAnimationViewModel model,
    @required double fontSize,
  }) : super(
        key: key, model: model,
        label: 'GAME OVER', fontColor: Colors.red, fontSize: fontSize);
}

/// ハイスコア表示をオーバラップしながらアニメーション表示するビューウィジェット
class HighScoreAnimationWidget extends RiseUpAnimationWidget<HighScoreAnimationViewModel> {
  const HighScoreAnimationWidget({
    Key key,
    @required HighScoreAnimationViewModel model,
    @required double fontSize,
  }) : super(
      key: key, model: model,
      label: 'high score update!\n  you got a level', fontColor: Colors.limeAccent, fontSize: fontSize);
}


/// 丸いタップボタンの UI表示を明滅アニメーション表示するビューウィジェット
class TapButtonAnimationWidget extends AbstractAnimationViewWidget<TapButtonAnimationViewModel> {
  final Color color;
  const TapButtonAnimationWidget({
      @required TapButtonAnimationViewModel model,
      @required this.color}) : super(model: model);

  @override
  AnimationController onCreateController(TickerProvider vsync) {
    return AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: vsync,
    )..forward();
  }

  @override
  List<Animation>  onCreateAnimations(AnimationController controller) {
    final Animation<Color> animeIn = ColorTween(begin: color, end: Colors.white)
        .animate(CurvedAnimation(
            parent: controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeInCirc)
          ),
        );

    final Animation<Color> animeOut = ColorTween(begin: Colors.white, end: color)
        .animate(CurvedAnimation(
            parent: controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCirc)
        ),
    );

    return <Animation>[animeIn, animeOut];
  }

  @override
  Widget onCreateChild(BuildContext context) {
    return null;
  }

  @override
  Widget onAnimationBuild(BuildContext context, Widget child,
      AnimationController controller, List<Animation> animations, {model}) {
    final Animation<Color> animeIn  = convertAnimation(animations[0]);
    final Animation<Color> animeOut = convertAnimation(animations[1]);

    // アニメーションのあるボタンは、アニメーションのオブジェクトで色を変化させる。
    return createTapButton(() => controller.value < 0.5 ? animeIn.value : animeOut.value);
  }

  @override
  Widget noAnimationBuild(BuildContext context, Widget child, {model}) {
    // アニメーションのないボタンの色は、固定にする。
    return createTapButton(() => color);
  }

  /// 丸いタップボタンを作成する。
  Widget createTapButton(Color Function() logic) {
    // パラメータ logic 関数オブジェクトで、ボタンの色を操作します。
    return OutlinedButton(
      onPressed: () {
        model.isAnimate = true;
        model.updateView();
        model.notify(model.index);
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(logic()),
        overlayColor: MaterialStateProperty.all<Color>(Colors.transparent),
        shape: MaterialStateProperty.all<OutlinedBorder>(
            const CircleBorder(side: BorderSide(color: Colors.black54, width: 2.0))
        ),
      ),
      child: const SizedBox(width: 100.0, height: 100.0),
    );
  }
}
