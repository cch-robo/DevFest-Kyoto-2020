#!/bin/bash
# flenv.sh ⇒ flutter environment ⇒ flutter 体験環境構築シェルスクリプト
# flutter for web を前提に、Android や iOS ネイティブ開発環境をインストールせず、
# flutter sdk のみの インストール / アンインストール を行えるようにして、
# 手軽に dart言語や flutter アプリの実行体験ができるようにします。

# flutter sdk install
FlutterInstallHelp() {
	echo "【概要】flenv.sh -install ⇒ flutter sdk インストール"
	echo "【使い方】カレントディレクトリ配下に、flutter SDK をインストールします。"
	echo ""
	echo "　カレントディレクトリに flutter_experience ディレクトリを追加し、"
	echo "　その配下に flutter SDK をインストールします。"
	echo "　当該コンソールでは、pub、dart と flutter コマンドが使えるようになります。"
	echo "　その他、IntelliJ IDEA Community Edition と dhttpd もインストールします。"
	echo ""
	echo "　インストールした flutter 体験環境をアンインストールしたい場合は、"
	echo "　flenv.sh -uninstall を実行してください。"
	echo ""
}
FlutterInstall() {
	# flutter sdk をリポジトリからクローンして、
	# flutter 開発環境を master channel 最新版かつ、flutter for web を有効にします。
	# 当該コンソール中のみで pub、dart と flutter コマンドが使えるよう、dart sdk と flutter sdk へのパスを通します。
	mkdir flutter_experience
	cd flutter_experience
	git clone https://github.com/flutter/flutter.git 
	echo ""
	echo "flutter sdk installed."
	echo ""
	
	# flutter体験環境構築シェルスクリプトを移動
	mv ../flenv.sh ./
	chmod +x ./flenv.sh

	export ORG_PATH=$PATH
	export FLUTTER_EXPERIENCE_ROOT=`pwd`
	export FLUTTER_ROOT=`pwd`/flutter
	export DART_SDK_PATH=$FLUTTER_ROOT/bin/cache/dart-sdk
	export PUB_CACHE=$FLUTTER_ROOT/.pub-cache

	echo ""
	echo "FLUTTER_ROOT=$FLUTTER_ROOT"
	echo "DART_SDK_PATH=$DART_SDK_PATH"
	echo "PUB_CACHE=$PUB_CACHE"
	echo ""

	echo "flutter doctor"
	$FLUTTER_ROOT/bin/flutter doctor
	echo ""

	echo "flutter channel beta"
	$FLUTTER_ROOT/bin/flutter channel beta
	echo ""

	echo "flutter upgrade"
	$FLUTTER_ROOT/bin/flutter upgrade
	echo ""

	echo "flutter/bin/flutter config --enable-web"
	$FLUTTER_ROOT/bin/flutter config --enable-web
	echo ""

	echo "flutter/bin/flutter config -no-enable-android"
	$FLUTTER_ROOT/bin/flutter config --no-enable-android
	echo ""

	echo "flutter/bin/flutter config --no-enable-ios"
	$FLUTTER_ROOT/bin/flutter config --no-enable-ios
	echo ""
	
	echo "flutter/bin/flutter config --no-enable-linux-desktop"
	$FLUTTER_ROOT/bin/flutter config --no-enable-linux-desktop 
	echo ""
	
	echo "flutter/bin/flutter config -no-enable-macos-desktop"
	$FLUTTER_ROOT/bin/flutter config --no-enable-macos-desktop
	echo ""

	# dhttpd 簡易 Web サーバをクローン
	git clone https://github.com/kevmoo/dhttpd.git
	cd dhttpd
	$DART_SDK_PATH/bin/pub get packages
	echo ""
	echo "The dhttpd was installed."
	echo ""
	echo "The 'flutter for web' application can host by this command."
	echo "dart dhttpd/bin/dhttpd.dart --host=IP_ADDRESS --port=8080 --path PROJECT_PATH/build/web"
	echo ""
	cd ..

	# IntelliJ Community Edition を dart/flutter プラグイン込みでインストール (2020/10/01版)
	# 【補足】
	#   IntelliJ や Plugin ダウンロード元 URL は、アーカイブやリポジトリからダウロードした際に
	#   Chrome 検証ツール Network で確認された、実際のダウンロード元 URL を利用しています。 
	#   
	#   IntelliJ IDEA / Other Versions
	#   https://www.jetbrains.com/ja-jp/idea/download/other.html
	#   
	#   JetBrains Plugins Repository
	#   https://plugins.jetbrains.com/
	if [ -f /vmlinuz ]; then
		# IntelliJ Community IDE for Linux
		wget https://download-cf.jetbrains.com/idea/ideaIC-2020.2.2.tar.gz

		tar -xzf ideaIC-2020.2.2.tar.gz
		mv idea-IC-202.7319.50 idea-CE
		rm ideaIC-2020.2.2.tar.gz

		# Dart plugin
		wget https://plugins.jetbrains.com/files/6351/97449/Dart-203.3645.34.zip
		unzip Dart-203.3645.34.zip
		mv Dart idea-CE/plugins
		rm Dart-203.3645.34.zip

		# flutter-intellij plugin
		wget https://plugins.jetbrains.com/files/9212/98175/flutter-intellij-50.0.4.zip
		unzip flutter-intellij-50.0.4.zip
		mv flutter-intellij idea-CE/plugins
		rm flutter-intellij-50.0.4.zip

		# IntelliJ IDEA は、idea.sh コマンドで起動します。
		export JAVA_HOME=$FLUTTER_EXPERIENCE_ROOT/idea-CE/jbr
		export IDE_HOME=$FLUTTER_EXPERIENCE_ROOT/idea-CE
		export PATH=$FLUTTER_ROOT/bin:$DART_SDK_PATH/bin:$JAVA_HOME/bin:$IDE_HOME/bin:`pwd`:$PATH:
		echo ""
		echo "JAVA_HOME=$JAVA_HOME"
		echo "IDE_HOME=$IDE_HOME"
		echo ""
		echo "The IntelliJ IDEA Community Edition was installed."
		echo "To launch the IntelliJ IDEA, you can use the idea.sh command."
		echo ""
	fi
	if [ -f /System/Applications/App\ Store.app/Contents/MacOS/App\ Store  ]; then
		# IntelliJ Community IDE for MAC（注意：元URL からリダイレクトされる）
		# wget https://download-cf.jetbrains.com/idea/ideaIC-2020.2.2.dmg
		curl -L -O https://download-cf.jetbrains.com/idea/ideaIC-2020.2.2.dmg
		hdiutil mount ideaIC-2020.2.2.dmg
		cp -r "/Volumes/IntelliJ IDEA CE/IntelliJ IDEA CE.app" $FLUTTER_EXPERIENCE_ROOT/idea-CE
		hdiutil detach "/Volumes/IntelliJ IDEA CE/"
		rm ideaIC-2020.2.2.dmg

		# Dart plugin
		# wget https://plugins.jetbrains.com/files/6351/97449/Dart-203.3645.34.zip
		curl -O https://plugins.jetbrains.com/files/6351/97449/Dart-203.3645.34.zip
		unzip Dart-203.3645.34.zip
		mv Dart idea-CE/Contents/plugins
		rm Dart-203.3645.34.zip

		# flutter-intellij plugin 
		# wget https://plugins.jetbrains.com/files/9212/98175/flutter-intellij-50.0.4.zip
		curl -O https://plugins.jetbrains.com/files/9212/98175/flutter-intellij-50.0.4.zip
		unzip flutter-intellij-50.0.4.zip
		mv flutter-intellij idea-CE/Contents/plugins
		rm flutter-intellij-50.0.4.zip

		# IntelliJ IDEA は、idea コマンドで起動します。
		export JAVA_HOME=$FLUTTER_EXPERIENCE_ROOT/idea-CE/Contents/jbr/Contents/Home
		export IDE_HOME=$FLUTTER_EXPERIENCE_ROOT/idea-CE/Contents
		# IntelliJ は、MacOS だと起動時の Java をデフォルト /usr/bin/java (*1) に設定し、
		# IDE 起動中は、/user/bin や /Library/Apple/usr/bin 等を PATH 変数先頭に設定することに注意
		# (*1) /usr/bin/java -> /System/Library/Frameworks/JavaVM.framework/Versions/Current/Commands/java
		export PATH=$FLUTTER_ROOT/bin:$DART_SDK_PATH/bin:$JAVA_HOME/bin:$IDE_HOME/MacOS:`pwd`:$PATH:
		echo ""
		echo "JAVA_HOME=$JAVA_HOME"
		echo "IDE_HOME=$IDE_HOME"
		echo ""
		echo "The IntelliJ IDEA Community Edition was installed."
		echo "To launch the IntelliJ IDEA, you can use the idea command."
		echo ""
	fi
	if [ -z "$IDE_HOME" ]; then
		export PATH=$FLUTTER_ROOT/bin:$DART_SDK_PATH/bin:`pwd`:$PATH:
		echo ""
		echo "想定外のOS環境です。"
		echo "IntelliJ IDEA が、インストールできませんでした。"
		echo ""
	fi
}

# flutter sdk uninstall
FlutterUninstallHelp() {
	echo "【概要】flenv.sh -uninstall ⇒ flutter sdk アンインストール"
	echo "【使い方】flutter_experience 配下の flutter SDK をアンインストールします。"
	echo ""
	echo "　flutter_experience の親ディレクトリで実行すると、"
	echo "　カレントディレクトリ配下の flutter_experience ディレクトリごと、"
	echo "　flutter SDK をアンインストール(全削除)します。"
	echo ""
	echo "　`flutter_experience`ディレクトリを全削除するため、"
	echo "　残したいファイルやディレクトリは、別の場所に移動させておいてください。"
	echo ""
}
FlutterUninstall() {
	# カレントディレクトリ配下の flutter sdk を全削除します。
	# カレントディレクトリから flutter_experimence ディレクトリも削除されます。
	# カレントディレクトリに flenv.sh シェルスクリプトを移動させます。
	if [ ! -e flutter_experience ] 
	then
		return 1
	fi

	cd flutter_experience
	mv -f flenv.sh ../
	flutter config --clear-features
	flutter doctor
	rm -r -f flutter

	cd ..
	rm -r -f flutter_experience
	return 0
}

# flutter experience resume
FlutterResumeHelp() {
	echo "【概要】flenv.sh -resume ⇒ flutter environment 復帰"
	echo "【使い方】flutter sdk を使った、flutter 体験コンソールを復帰します。"
	echo ""
	echo "　カレントディレクトリ配下の flutter sdk を使った、"
	echo "　flutter 体験コンソールを復帰させます。"
	echo "　pub、dart、flutter コマンドや IntelliJ IDEA が使えるようになります。"
	echo ""
}
FlutterResume() {
	# flutter 体験コンソールを復帰させます。
	if [ ! -e ../flutter_experience ]; then
		echo ""
		echo "カレントディレクトリは、flutter 体験ディレクトリではありません。"
		echo ""
		return 1
	elif [ ! -e ../flutter_experience/flutter ]; then
		echo ""
		echo "flutter 体験環境ががインストールされていません。"
		echo ""
		return 1
	fi

	export ORG_PATH=$PATH
	export FLUTTER_EXPERIENCE_ROOT=`pwd`
	export FLUTTER_ROOT=`pwd`/flutter
	export DART_SDK_PATH=$FLUTTER_ROOT/bin/cache/dart-sdk
	export PUB_CACHE=$FLUTTER_ROOT/.pub-cache

	$FLUTTER_ROOT/bin/flutter channel beta
	$FLUTTER_ROOT/bin/flutter upgrade
	$FLUTTER_ROOT/bin/flutter config --enable-web
	$FLUTTER_ROOT/bin/flutter config --no-enable-android
	$FLUTTER_ROOT/bin/flutter config --no-enable-ios
	$FLUTTER_ROOT/bin/flutter config --no-enable-linux-desktop 
	$FLUTTER_ROOT/bin/flutter config --no-enable-macos-desktop

	if [ -f /vmlinuz ]; then
		export JAVA_HOME=$FLUTTER_EXPERIENCE_ROOT/idea-CE/jbr
		export IDE_HOME=$FLUTTER_EXPERIENCE_ROOT/idea-CE
		export PATH=$FLUTTER_ROOT/bin:$DART_SDK_PATH/bin:$JAVA_HOME/bin:$IDE_HOME/bin:`pwd`:$PATH:
	elif [ -f /System/Applications/App\ Store.app/Contents/MacOS/App\ Store  ]; then
		export JAVA_HOME=$FLUTTER_EXPERIENCE_ROOT/idea-CE/Contents/jbr/Contents/Home
		export IDE_HOME=$FLUTTER_EXPERIENCE_ROOT/idea-CE/Contents
		export PATH=$FLUTTER_ROOT/bin:$DART_SDK_PATH/bin:$JAVA_HOME/bin:$IDE_HOME/MacOS:`pwd`:$PATH:
	else
		export PATH=$FLUTTER_ROOT/bin:$DART_SDK_PATH/bin:`pwd`:$PATH:
		echo ""
		echo "想定外のOS環境です。"
		echo "IntelliJ IDEA が、インストールできていません。"
		echo ""
	fi
	return 0
}


# flutter for web server launch (Web App contents deploy)
FlutterServerHelp() {
	echo "【概要】flenv.sh -server [IP_ADDR] ⇒ flutter プロジェクト Webアプリ外部公開"
	echo "【使い方】ビルド済 Web アプリを外部端末から参照可能にするサーバを起動します。"
	echo ""
	echo "　flenv.sh -server は、ビルドされた Web アプリ・コンテンツを"
	echo "　外部の PCや スマホからアクセス可能にしてくれる Webサーバを起動します。"
	echo "　flutter プロジェクトのディレクトリ(pubspec.yamlがある)で実行してください。"
	echo ""
	echo "　停止させる場合は、flutter体験コンソールで CTRL+C を入力してください。"
	echo "　オプションの IP_ADDR があれば、サーバ IPアドレスを IP_ADDR に指定します。"
	echo ""
	echo "　注意）kevmoo/dhttpd サーバを使って、build/web のコンテンツをホストします"
	echo "　　　　flutter run -d chrome でアプリを起動すると、Local Loopback Address/"
	echo "　　　　localhost 以外からアクセスできないので、dhttpd を使って回避します。"
	echo "　　　　https://github.com/kevmoo/dhttpd"
	echo ""
}
FlutterServer() {
	# flutter 体験プロジェクトの Web アプリ・コンテンツを提供するサーバを起動します。
	if [ ! -e ./build/web ] 
	then
		return 1
	fi
	
	echo "flutter体験PC IPアドレス一覧"
	ifconfig | grep 'inet ' 
	if [ $# -eq 1 ] 
	then
		export IP_ADDR=$1
	else
		export IP_ADDR=`ipconfig getifaddr en0`
	fi
	if [ "$IP_ADDR" = "" ]
	then
		export IP_ADDR=UNKNOWN
	fi

	echo ""
	echo "flutter体験PC IPアドレスは、$IP_ADDR です。"
	echo "外部の PCや スマホの Webブラウザを使う場合は、"
	echo "http://$IP_ADDR:8080/index.html を開いてください。"
	echo ""
	echo "Webサーバを停止させる場合は、CTRL+C を入力してください。"
	echo ""

	echo "dart dhttpd/bin/dhttpd.dart --host=$IP_ADDR --port=8080 --path build/web"
	dart $FLUTTER_EXPERIENCE_ROOT/dhttpd/bin/dhttpd.dart --host=$IP_ADDR --port=8080 --path build/web
	if [ $? -ne 0 ] 
	then
		echo "サーバ起動に失敗しました。"
		echo "オプションの IP_ADDR に、flutter体験PC IPアドレスを確認して"
		echo "flenv.sh -server 192.168.0.5 のようにして再実行してみてください。"
	fi
	return 0
}


# help
Help() {
	echo "flenv.sh: flutter environment/ flutter 体験環境構築シェルスクリプト"
	echo "　dart や flutter プログラムを手軽に体験してもらえるよう、"
	echo "　flutter sdk のインストールと環境設定を行う手軽なコマンドを提供します。"
	echo "　初学者躓きの元となる、iOS や Android 開発環境のインストールや設定を行なわず、"
	echo "　PC や スマートフォンのブラウザで、アプリ実行(flutter for Web)が体験できます。"
	echo ""
	echo "flenv.sh コマンドオプション"
	echo "    -install   ⇒ flutter sdk をカレントディレクトリ配下にインストール"
	echo "    -uninstall   ⇒ カレントディレクトリ配下の flutter sdk をアンインストール"
	echo "    -resume    ⇒ flutter 体験コンソール 復帰"
	echo "    -server    ⇒ flutter 体験プロジェクト Webアプリ外部公開"
	echo ""
	echo "    -help -install   ⇒ flutter sdk インストールの詳細説明"
	echo "    -help -uninstall   ⇒ flutter sdk アンインストールの詳細説明"
	echo "    -help -resume    ⇒ flutter 体験コンソール復帰の詳細説明"
	echo "    -help -server    ⇒ flutter 体験プロジェクト Webアプリ外部公開の詳細説明"
	echo ""
}


###################################
# コマンドライン・オプション処理
###################################

#オプションチェック
if [ $# -eq 1 ]
then
	if [ "$1" = "-install" ]
	then
		# flutter sdk install コマンド (新シェル実行)
		FlutterInstall
		echo ""
		echo "flutter 体験環境をインストールしました。"
		echo "もしも flutter 体験環境をアンインストールする場合は、"
		echo "flenv.sh -uninstall を実行してください。"
		echo ""
		echo "flutter experience コンソールを開きます。"
		# MacOS では、ls オプジョンが使えないため利用しない。
		# $PS1 でプロンプト表示を設定し、ls --color:auto で、
		# $LS_COLORS に設定された Ls コマンドの色分け指定を有効にする。
		# echo '#!/bin/bash --norc' > env.sh
		# echo 'export PS1="\[\e[32m\e[1m\]flutter_experience: \[\e[0m\]\W \$ "' >> env.sh
		# echo 'alias ls="ls --color=auto"' >> env.sh
		# echo 'rm env.sh' >> env.sh
		# bash --rcfile env.sh
		export PS1="\[\e[32m\e[1m\]flutter_experience: \[\e[0m\]\W \$ "
		bash --norc
		exit 0
	elif [ "$1" = "-uninstall" ]
	then
		# flutter sdk uninstall コマンド (新シェル終了)
		FlutterUninstall
		if [ $? -eq 0 ] 
		then
			echo ""
			echo "flutter 体験環境をアンインストールしました。"
			echo ""
			echo "flutter experience コンソールはもう有効では有りません。"
			echo "ターミナルを閉じてください。"
		else
			echo ""
			echo "flutter experience ディレクトリがありません。"
			exit 1
		fi
		exit 0
	elif [ "$1" = "-resume" ]
	then
		# flutter experience 復帰コマンド (新シェル実行)
		FlutterResume
		if [ $? -eq 0 ] 
		then
			echo ""
			echo "flutter experience コンソールを開きます。"
			# MacOS では、ls オプジョンが使えないため利用しない。
			# $PS1 でプロンプト表示を設定し、ls --color:auto で、
			# $LS_COLORS に設定された Ls コマンドの色分け指定を有効にする。
			# echo '#!/bin/bash --norc' > env.sh
			# echo 'export PS1="\[\e[32m\e[1m\]flutter_experience: \[\e[0m\]\W \$ "' >> env.sh
			# echo 'alias ls="ls --color=auto"' >> env.sh
			# echo 'rm env.sh' >> env.sh
			# bash --rcfile env.sh
			export PS1="\[\e[32m\e[1m\]flutter_experience: \[\e[0m\]\W \$ "
			bash --norc
		else
			echo ""
			echo "flutter 体験環境復帰に失敗しました。"
			exit 1
		fi
		exit 0
	fi
fi

if [ $# -gt 0 ]
then
	if [ "$1" = "-server" ]
	then
		# flutter 体験プロジェクト サーバ起動
		FlutterServer $2
		if [ $? -ne 0 ] 
		then
			echo ""
			echo "flutter 体験環境が構築されていないか、"
			echo "flutter プロジェクトの Webアプリ・ビルドが実行されていません。"
			echo "flenv.sh -install や、プロジェクトで flutter build web を実行してから、"
			echo "flutter 体験プロンプトで実行しなおしてください。"
			exit 1
		fi
		exit 0
	fi
fi

if [ "$1" = "-help" ]
then 
	if [ "$2" = "-install" ]
	then 
		FlutterInstallHelp
		exit 0
	elif [ "$2" = "-uninstall" ]
	then 
		FlutterUninstallHelp
		exit 0
	elif [ "$2" = "-resume" ]
	then 
		FlutterResumeHelp
		exit 0
	elif [ "$2" = "-server" ]
	then 
		FlutterServerHelp
		exit 0
	fi
fi

# オプション指定なし
Help
exit 1
