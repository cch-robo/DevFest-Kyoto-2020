import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memojudge/src/library/model_mixin.dart';

/// step2-3
void startApp() {
  runApp(MyApp());
}

// provider パッケージ＋ViewModel＆Modelを使った、MVVM パターン実装
// CountView に CountViewModel をバインドして、
// CountViewModel に CountModel をバインド(所有)させて、
// CountModel でカウントを操作して、CountViewModelに通知し、
// CountViewModel で、UI状態のCountModel従属と UI表示の更新を行う。

/// ページ全体にモデル（ビジネスロジックとデータモデル）を提供する Provider
class MyProvider {
  CountModel countModel;
  CountViewModel count;

  Widget create() {
    countModel = CountModel();
    count = CountViewModel(countModel);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => count),
      ],
      child: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

/// カウントを管理する Model
class CountModel with Model {
  int _count = 0;
  int get count => _count;

  void incrementCounter() {
    _count++;
    updateViewModels();
  }
}

/// カウントの UI表示に関する、プロパティとコマンドを提供する ViewModel
class CountViewModel with ChangeNotifier, ViewModel {
  final CountModel countModel;
  CountViewModel(this.countModel) {
    countModel.bindUpdate(onUpdate);
  }

  int get count => countModel.count;

  void updateCount() {
    countModel.incrementCounter();
  }

  @override
  void onUpdate(Model model) {
    if (model?.hashCode == countModel.hashCode ?? false) {
      notifyListeners();
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
      home: MyProvider().create(),
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
      body: Center(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<CountViewModel>().updateCount(),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
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
