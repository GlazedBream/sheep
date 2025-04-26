//allprojects {
//    repositories {
//        google()
//        mavenCentral()
//    }
//}
//
//val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
//rootProject.layout.buildDirectory.value(newBuildDir)
//
//subprojects {
//    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//    project.layout.buildDirectory.value(newSubprojectBuildDir)
//}
//subprojects {
//    project.evaluationDependsOn(":app")
//}
//
//tasks.register<Delete>("clean") {
//    delete(rootProject.layout.buildDirectory)
//}
//
//plugins {
//    id 'com.android.application'
//    id 'kotlin-android'
//}
//
//android {
//    namespace "com.example.myapp"
//    compileSdkVersion 33
//
//    defaultConfig {
//        applicationId "com.example.myapp"
//        minSdkVersion 19
//        targetSdkVersion 33
//        versionCode 1
//        versionName "1.0"
//    }
//
//    buildTypes {
//        release {
//            minifyEnabled false
//            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
//        }
//    }
//
//    compileOptions {
//        sourceCompatibility JavaVersion.VERSION_17
//                targetCompatibility JavaVersion.VERSION_17
//    }
//
//    kotlinOptions {
//        jvmTarget = '17'
//    }
//}
//
//dependencies {
//    implementation "org.jetbrains.kotlin:kotlin-stdlib:1.8.0"
//    implementation 'androidx.core:core-ktx:1.10.1'
//    implementation 'androidx.appcompat:appcompat:1.6.1'
//    implementation 'com.google.android.material:material:1.9.0'
//}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}