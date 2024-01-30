import React from 'react';
import {StyleSheet, Text, View} from 'react-native';

export const Composer = ({}) => {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Hey Mammoth</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#151515',
  },
  title: {
    color: '#BCBCBC',
    fontSize: 18,
  },
});
