import 'package:package_info/package_info.dart';

class PackageInfoController {
    // Singleton implementation
    static final PackageInfoController _instance = PackageInfoController._internal();
    factory PackageInfoController() => _instance;

    // Internal fields
    PackageInfo _packageInfo;

    PackageInfoController._internal();

    Future<PackageInfo> getPackageInfo() async {
        if (_packageInfo == null)
            _packageInfo = await PackageInfo.fromPlatform();
        return _packageInfo;
    }

    void dispose() {

    }

}
