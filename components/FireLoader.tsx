import React, { useEffect, useRef } from 'react';
import { View, Animated, StyleSheet } from 'react-native';

export default function FireLoader() {
  // Animated values for scaling, shaking, and glowing
  const centerScaleY = useRef(new Animated.Value(1)).current;
  const leftTranslateY = useRef(new Animated.Value(0)).current;
  const rightTranslateY = useRef(new Animated.Value(0)).current;
  const glowOpacity = useRef(new Animated.Value(0.6)).current;

  useEffect(() => {
    // 1. Center flame scale animation
    Animated.loop(
      Animated.sequence([
        Animated.timing(centerScaleY, {
          toValue: 1.15,
          duration: 600,
          useNativeDriver: true,
        }),
        Animated.timing(centerScaleY, {
          toValue: 0.95,
          duration: 500,
          useNativeDriver: true,
        }),
        Animated.timing(centerScaleY, {
          toValue: 1.0,
          duration: 400,
          useNativeDriver: true,
        }),
      ])
    ).start();

    // 2. Left flame shake/bounce animation
    Animated.loop(
      Animated.sequence([
        Animated.timing(leftTranslateY, {
          toValue: -8,
          duration: 400,
          useNativeDriver: true,
        }),
        Animated.timing(leftTranslateY, {
          toValue: 4,
          duration: 500,
          useNativeDriver: true,
        }),
        Animated.timing(leftTranslateY, {
          toValue: 0,
          duration: 300,
          useNativeDriver: true,
        }),
      ])
    ).start();

    // 3. Right flame shake/bounce animation
    Animated.loop(
      Animated.sequence([
        Animated.timing(rightTranslateY, {
          toValue: 6,
          duration: 500,
          useNativeDriver: true,
        }),
        Animated.timing(rightTranslateY, {
          toValue: -6,
          duration: 400,
          useNativeDriver: true,
        }),
        Animated.timing(rightTranslateY, {
          toValue: 0,
          duration: 300,
          useNativeDriver: true,
        }),
      ])
    ).start();

    // 4. Bottom flame glow/pulse animation
    Animated.loop(
      Animated.sequence([
        Animated.timing(glowOpacity, {
          toValue: 1.0,
          duration: 800,
          useNativeDriver: true,
        }),
        Animated.timing(glowOpacity, {
          toValue: 0.4,
          duration: 800,
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, [centerScaleY, glowOpacity, leftTranslateY, rightTranslateY]);

  return (
    <View style={styles.container}>
      {/* Outer Glow Indicator */}
      <Animated.View style={[styles.bottomGlow, { opacity: glowOpacity }]} />

      {/* Left Flame */}
      <Animated.View 
        style={[
          styles.flame, 
          styles.leftFlame, 
          { transform: [{ translateY: leftTranslateY }, { rotate: '35deg' }] }
        ]} 
      />

      {/* Right Flame */}
      <Animated.View 
        style={[
          styles.flame, 
          styles.rightFlame, 
          { transform: [{ translateY: rightTranslateY }, { rotate: '55deg' }] }
        ]} 
      />

      {/* Center Flame */}
      <Animated.View 
        style={[
          styles.flame, 
          styles.centerFlame, 
          { transform: [{ scaleY: centerScaleY }, { rotate: '45deg' }] }
        ]} 
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: 80,
    height: 80,
    position: 'relative',
    justifyContent: 'center',
    alignItems: 'center',
  },
  flame: {
    position: 'absolute',
    borderRadius: 50,
    borderTopRightRadius: 0, // Creates the teardrop flame shape
  },
  centerFlame: {
    width: 32,
    height: 32,
    backgroundColor: '#ef5a00',
    shadowColor: '#d43300',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.8,
    shadowRadius: 10,
    elevation: 8,
  },
  leftFlame: {
    width: 24,
    height: 24,
    backgroundColor: '#d43300',
    opacity: 0.85,
    left: 18,
    bottom: 24,
  },
  rightFlame: {
    width: 24,
    height: 24,
    backgroundColor: '#ff7800',
    opacity: 0.9,
    right: 18,
    bottom: 24,
  },
  bottomGlow: {
    position: 'absolute',
    bottom: 12,
    width: 50,
    height: 12,
    borderRadius: 10,
    backgroundColor: '#ff7800',
    filter: 'blur(6px)', // Falls back to blur opacity styling on older engines
    opacity: 0.6,
  }
});
