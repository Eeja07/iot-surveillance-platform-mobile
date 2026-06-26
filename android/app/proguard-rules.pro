# Mengabaikan peringatan untuk TensorFlow Lite GPU Delegate jika tidak digunakan
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.lite.**

# Menjaga kelas TensorFlow Lite agar tidak terhapus sembarangan
-keep class org.tensorflow.lite.** { *; }