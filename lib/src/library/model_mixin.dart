/// UI表現モデルを更新させるための関数型
typedef UpdateViewModel = void Function(Model model);

/// ビジネスロジックとデータモデルを提供する、ドメインモデルを定義する基盤クラス。
mixin Model {
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
    for (UpdateViewModel update in _updateViewModels) {
      update(this);
    }
  }
}

mixin ViewModel {
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

