import React, {useCallback, useEffect, useMemo} from 'react';
import {
  StyleSheet,
  Text,
  NativeModules,
  Button,
  AppRegistry,
  Pressable,
  SafeAreaView,
  ScrollView,
  KeyboardAvoidingView,
  Image,
  View,
} from 'react-native';
import {RichEditor} from 'react-native-pell-rich-editor';
import {MenuView} from '@react-native-menu/menu';

const nativeNavigator = NativeModules.Navigator;

export const Composer = ({rootTag, current}) => {
  const richText = React.useRef();
  const currentAccount = useMemo(() => JSON.parse(current), [current]);

  const LeftButton = useCallback(
    () => (
      <Button
        style={styles.closeButton}
        onPress={() => nativeNavigator.dismissFromReactTag(rootTag)}
        title="Cancel"
        color="#fff"
      />
    ),
    [rootTag],
  );

  const RightButton = useCallback(
    () => (
      <Pressable
        onPress={() => nativeNavigator.dismissFromReactTag(rootTag)}
        style={styles.postButton}>
        <Text style={styles.postButtonText}>Post</Text>
      </Pressable>
    ),
    [rootTag],
  );

  useEffect(() => {
    const left = registerCustomButtons([
      {
        id: 'mammoth.nav.cancel',
        title: 'Cancel',
        component: LeftButton,
        image: null,
        disabled: false,
      },
    ]);

    const right = registerCustomButtons([
      {
        id: 'mammoth.nav.post',
        title: 'Post',
        component: RightButton,
        disabled: true,
      },
    ]);

    nativeNavigator.registerRootView(rootTag, {
      leftButtons: left,
      rightButtons: right,
    });
    nativeNavigator.onRootViewEnteredHierarchy(() => {
      nativeNavigator.registerRootView(rootTag, {
        leftButtons: left,
        rightButtons: right,
      });
    });

    return () => nativeNavigator.unregisterRootView(rootTag);
  }, [LeftButton, RightButton, rootTag]);

  useEffect(() => {
    richText.current?.setFontSize(4);
    richText.current?.focusContentEditor();
  }, [richText]);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView>
        <KeyboardAvoidingView>
          <View style={styles.header}>
            <Image
              style={styles.avatar}
              source={{
                uri: currentAccount.account.avatar,
              }}
            />
            <MenuView
              title=""
              onPressAction={({nativeEvent}) => {
                console.warn(JSON.stringify(nativeEvent));
              }}
              actions={[
                {
                  id: 'option1',
                  title: 'Option 1',
                  state: 'on',
                },
                {
                  id: 'option2',
                  title: 'Option 2',
                  state: 'on',
                },
              ]}
              shouldOpenOnLongPress={false}>
              <Text style={styles.reach}>Anyone ▾</Text>
            </MenuView>
          </View>
          <RichEditor
            initialFocus={true}
            placeholder="What's happening?"
            editorStyle={styles.richEditor}
            ref={richText}
            style={styles.richEditorContainer}
            onChange={descriptionText => {
              // console.log('descriptionText:', descriptionText);
            }}
          />
        </KeyboardAvoidingView>
      </ScrollView>
    </SafeAreaView>
  );
};

const registerCustomButtons = buttons => {
  if (!buttons) {
    return;
  }
  // Iterate through currentRoute's navigator buttons to register any custom nav button components
  return buttons.map(button => {
    if (button.component) {
      AppRegistry.registerComponent(button.id, () => button.component);
      return {
        ...button,
        // Replace the component with an id so native can use it to fetch the RN view
        component: button.id,
      };
    }
    // Handle images
    if (button.image) {
      const resolveAssetSource = require('react-native/Libraries/Image/resolveAssetSource');
      const resolvedImage = resolveAssetSource(button.image);
      return {
        ...button,
        image: resolvedImage,
      };
    }
    return button;
  });
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'stretch',
    backgroundColor: '#151515',
    marginHorizontal: 16,
  },
  reach: {
    color: '#fff',
    fontSize: 15,
    paddingHorizontal: 16,
    paddingTop: 4,
    height: 30,
    borderColor: '#fff',
    borderWidth: 1,
    borderRadius: 15,
    fontWeight: '500',
    marginLeft: 8,
  },
  closeButton: {
    color: '#BCBCBC',
  },
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
  header: {
    flex: 1,
    flexDirection: 'row',
  },
  richEditor: {
    backgroundColor: '#151515',
    color: '#fff',
    placeholderColor: '#595959',
  },
  richEditorContainer: {
    margin: 0,
    padding: 0,
    marginLeft: 18,
    fontSize: 14,
  },
  avatar: {
    width: 36,
    height: 36,
    overflow: 'hidden',
    borderRadius: 18,
  },
});
