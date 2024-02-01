import React from 'react';
import {NativeModules, Pressable, StyleSheet, Text} from 'react-native';
const nativeNavigator = NativeModules.Navigator;

type Props = {
  screenId: number;
};
export const RightButton = ({screenId}: Props) => {
  return (
    <Pressable
      onPress={() => nativeNavigator.dismissFromReactTag(screenId)}
      style={styles.postButton}>
      <Text style={styles.postButtonText}>Post</Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  postButton: {
    backgroundColor: '#818181',
    overflow: 'hidden',
    paddingLeft: 14,
    paddingRight: 14,
    paddingTop: 4,
    paddingBottom: 4,
    borderRadius: 20,
  },
  postButtonText: {
    color: '#1B1B1B',
    fontSize: 16,
    fontWeight: '600',
  },
});
