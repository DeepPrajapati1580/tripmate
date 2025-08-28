// Project-level Gradle build configuration in Kotlin DSL

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Flutter custom build directory
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileSdkVersion(35) // match your Flutter compileSdkVersion
        }
    }
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ✅ Plugins in Kotlin DSL format (replaces Groovy classpath/apply)
plugins {
    id("com.google.gms.google-services") apply false
}
