allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val projectDrive = project.projectDir.absolutePath.substring(0, 1).lowercase()
    val buildDrive = newBuildDir.asFile.absolutePath.substring(0, 1).lowercase()
    if (projectDrive == buildDrive || project.name == "app") {
        try {
            val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
            project.layout.buildDirectory.value(newSubprojectBuildDir)
        } catch (e: Exception) {
            // Ignore if it fails due to different roots
        }
    } else {
        // Fallback to a temp directory on the same drive as the plugin to avoid "different roots" AGP bug
        val tempDir = System.getProperty("java.io.tmpdir")
        val fallbackBuildDir = file("$tempDir/flutter_plugin_builds/${project.name}")
        project.layout.buildDirectory.set(fallbackBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
