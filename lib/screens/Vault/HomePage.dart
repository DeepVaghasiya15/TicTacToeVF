import 'package:flutter/material.dart';
import 'package:flutter_tic_tac_toe/screens/Vault/CameraScreen.dart';
import 'package:flutter_tic_tac_toe/screens/Vault/DataScreen.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  List<bool> buttonStates = [false, false, false];
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  void _onButtonPressed(int index) {
    setState(() {
      buttonStates[index] = true;
      if (buttonStates.every((state) => state)) {
            {Navigator.push(context, MaterialPageRoute(builder: (BuildContext context)=> const DataScreen()));}
        buttonStates = [false, false, false];
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      buttonStates = [false, false, false];
    });
  }

  @override
  Widget build(BuildContext context) {
    // final appState = Provider.of<AppState>(context);
    final size = MediaQuery.of(context).size;
    final buttonWidth = size.width * 0.1;
    final buttonHeight = size.height * 0.04;
    const double opacity = 0.02;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Vault",
            style: TextStyle(
              fontFamily: 'Lato',
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: Theme.of(context).colorScheme.inversePrimary,
            )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              size: 28,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            onPressed: () => Navigator.pushNamed(context, '/SettingScreen'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: IconButton(
              icon: Icon(
                Icons.camera_alt_outlined,
                color: Theme.of(context).colorScheme.inversePrimary,
                size: 60,
              ),
              onPressed: (){Navigator.push(context, MaterialPageRoute(builder: (BuildContext context)=> CameraScreen()));},
            ),
          ),
          // Hidden buttons
          Positioned(
            top: size.height * 0.05,
            left: size.width * 0.05,
            child: Opacity(
              opacity: opacity,
              child: SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () => _onButtonPressed(0),
                  child: const Text(''),
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.05,
            right: size.width * 0.05,
            child: Opacity(
              opacity: opacity,
              child: SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () => _onButtonPressed(1),
                  child: const Text(''),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.1,
            right: size.width * 0.45,
            child: Opacity(
              opacity: opacity,
              child: SizedBox(
                width: buttonWidth,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () => _onButtonPressed(2),
                  child: const Text(''),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
