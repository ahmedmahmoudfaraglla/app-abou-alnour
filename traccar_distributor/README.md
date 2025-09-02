# Traccar Distributor

Traccar Distributor هو تطبيق Flutter يهدف إلى إدارة وتتبع الأجهزة باستخدام واجهة برمجة التطبيقات الخاصة بـ Traccar. يوفر التطبيق واجهة مستخدم بسيطة لتسجيل الدخول، عرض الأجهزة، وإرسال الأوامر.

## هيكل المشروع

- **lib/api.dart**: يحتوي على تعريف الفئة `TraccarApi` التي تتعامل مع واجهة برمجة التطبيقات. 
  - الخصائص:
    - `baseUrl`: عنوان URL الأساسي للواجهة.
    - `_dio`: كائن من نوع `Dio` لإجراء الطلبات.
    - `_jar`: كائن من نوع `CookieJar` لإدارة الكوكيز.
  - الدوال:
    - `login(String email, String password)`: تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور.
    - `devices()`: استرجاع قائمة الأجهزة.
    - `positionById(int id)`: استرجاع موقع جهاز معين باستخدام معرفه.
    - `commandTypes(int deviceId)`: استرجاع أنواع الأوامر لجهاز معين.
    - `sendCommand({required int deviceId, required String type, Map<String,dynamic>? params})`: إرسال أمر لجهاز معين.

- **lib/models.dart**: يحتوي على تعريف الفئتين `Device` و`Position`.
  - **Device**:
    - الخصائص:
      - `id`: معرف الجهاز.
      - `name`: اسم الجهاز.
      - `positionId`: معرف الموقع (اختياري).
      - `status`: حالة الجهاز (اختياري).
    - دالة المصنع `fromJson(Map<String,dynamic> j)` لتحويل JSON إلى كائن `Device`.
  
  - **Position**:
    - الخصائص:
      - `lat`: خط العرض.
      - `lon`: خط الطول.
      - `speed`: السرعة (اختياري).
      - `fixTime`: وقت التثبيت.
    - دالة المصنع `fromJson(Map<String,dynamic> j)` لتحويل JSON إلى كائن `Position`.

- **lib/main.dart**: نقطة دخول التطبيق. يحتوي على الفئة `TraccarApp` التي تقوم بتهيئة التطبيق.
  - `main()`: دالة البداية التي تقوم بتشغيل التطبيق.
  - `LoginPage`: صفحة تسجيل الدخول التي تحتوي على حقول لإدخال رقم الهاتف وكلمة المرور.
  - `DevicesPage`: صفحة تعرض قائمة الأجهزة المتاحة.
  - `DeviceMapPage`: صفحة تعرض خريطة لجهاز معين مع إمكانية إرسال أوامر.
  - `_SpeedDialog`: حوار لتحديد السرعة.

- **.github/workflows/android-apk.yml**: ملف إعدادات CI/CD لبناء تطبيق Android. يحتوي على خطوات لبناء التطبيق وتأكيد وجود إذن الإنترنت.

- **pubspec.yaml**: ملف إعدادات المشروع الذي يحدد اسم المشروع، الإصدار، والاعتماديات المطلوبة. 

## كيفية الاستخدام

1. قم بتثبيت الاعتماديات باستخدام الأمر:
   ```
   flutter pub get
   ```

2. قم بتشغيل التطبيق باستخدام الأمر:
   ```
   flutter run
   ```

3. افتح تبويب Actions في الريبو وشغّل Android APK (Debug) ثم نزّل Artifact: app-debug.apk.