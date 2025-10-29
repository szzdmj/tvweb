#!/usr/bin/env sh
set -e

APP_HOME=$(cd "$(dirname "$0")" && pwd)
APP_BASE_NAME=$(basename "$0")
DEFAULT_JVM_OPTS=""

WRAPPER_JAR="$APP_HOME/gradle/wrapper/gradle-wrapper.jar"
WRAPPER_URL="https://github.com/gradle/gradle/raw/v7.5.1/gradle/wrapper/gradle-wrapper.jar"

if [ ! -f "$WRAPPER_JAR" ]; then
    mkdir -p "$(dirname "$WRAPPER_JAR")"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$WRAPPER_JAR" "$WRAPPER_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$WRAPPER_JAR" "$WRAPPER_URL"
    else
        echo "ERROR: Neither curl nor wget is available to download Gradle wrapper." >&2
        exit 1
    fi
fi

CLASSPATH="$WRAPPER_JAR"

if [ -n "$JAVA_HOME" ]; then
    if [ -x "$JAVA_HOME/jre/sh/java" ]; then
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ]; then
        echo "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME" >&2
        exit 1
    fi
else
    JAVACMD="java"
fi

exec "$JAVACMD" $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS \
  "-Dorg.gradle.appname=$APP_BASE_NAME" -classpath "$CLASSPATH" \
  org.gradle.wrapper.GradleWrapperMain "$@"
