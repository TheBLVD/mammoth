import {MenuView} from '@react-native-menu/menu';
import React, {useEffect, useMemo} from 'react';
import {
  Image,
  KeyboardAvoidingView,
  SafeAreaView,
  ScrollView,
  Text,
  View,
} from 'react-native';
import {RichEditor} from 'react-native-pell-rich-editor';
import {useScreenRegister} from './hooks';
import {styles} from './style';

type Props = {
  rootTag: number;
  current: any;
};

export const Composer = ({rootTag, current}: Props) => {
  useScreenRegister(rootTag);

  const richText = React.useRef();
  const currentAccount = useMemo(() => {
    try {
      JSON.parse(current);
    } catch (error) {}
  }, [current]);

  useEffect(() => {
    (richText.current as unknown as RichEditor)?.setFontSize(4);
    (richText.current as unknown as RichEditor)?.focusContentEditor();
  }, [richText]);

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView>
        <KeyboardAvoidingView>
          <View style={styles.header}>
            <Image
              style={styles.avatar}
              source={{
                uri: currentAccount?.account?.avatar,
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
                  state: 'off',
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
