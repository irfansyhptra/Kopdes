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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    val configureProject = {
        plugins.withId("com.android.library") {
            configure<com.android.build.gradle.LibraryExtension> {
                compileSdk = 36
                println("🤖 GRADLE: Setting compileSdk = 36 for library project: ${project.name}")
                if (namespace == null) {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestContent = manifestFile.readText()
                        val matchResult = Regex("package=\"([^\"]+)\"").find(manifestContent)
                        if (matchResult != null) {
                            namespace = matchResult.groupValues[1]
                        } else {
                            namespace = "com.kopdes.plugins." + project.name.replace("-", "_")
                        }
                    } else {
                        namespace = "com.kopdes.plugins." + project.name.replace("-", "_")
                    }
                }
            }
        }
    }
    if (project.state.executed) {
        configureProject()
    } else {
        project.afterEvaluate {
            configureProject()
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
