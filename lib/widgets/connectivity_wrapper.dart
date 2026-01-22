import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/services/connectivity_service.dart';
import 'package:pawtastic/widgets/connection_error_widget.dart';

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        if (!connectivity.isOnline) {
          return Scaffold(
            body: ConnectionErrorWidget(
              onRetry: () => connectivity.checkConnectivity(),
            ),
          );
        }
        return child;
      },
    );
  }
}
