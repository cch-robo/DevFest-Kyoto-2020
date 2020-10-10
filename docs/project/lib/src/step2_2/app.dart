import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// provider パッケージを使った、VM パターン実装
// CountView に CountViewModel をバインドして、
// CountViewModel で、UI状態の変更と UI表示の更新を行う。

/// step2-2
void startApp() {
  runApp(MyApp());
}

/// ページ全体にモデル（ビジネスロジックとデータモデル）を提供する Provider
class MyProvider {
  Widget create() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CountViewModel()),
      ],
      child: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

/// カウントの UI表示に関する、値とロジックを提供する ViewModel
class CountViewModel with ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void incrementCounter() {
    _count++;
    notifyListeners();
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
  const MyHomePage({Key key, this.title}) : super(key: key);
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
        onPressed: () => context.read<CountViewModel>().incrementCounter(),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

/// カウントの UI表示を行う View
class CountView extends StatelessWidget {
  const CountView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      '${context.watch<CountViewModel>().count}',
      style: Theme.of(context).textTheme.headline4,
    );
  }
}
