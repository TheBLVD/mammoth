import {StyleSheet} from 'react-native';

export const styles = StyleSheet.create({
  container: {
    // flex: 1,
    // justifyContent: 'center',
    // alignItems: 'stretch',
    backgroundColor: '#151515',
    marginHorizontal: 16,
  },
  page: {
    // flex: 1,
  },
  postCard: {
    flex: 1,
    marginLeft: 20,
    marginTop: 20,
    // height: 100,
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
    marginLeft: 38,
    fontSize: 14,
    height: 200,
  },
  avatar: {
    width: 36,
    height: 36,
    overflow: 'hidden',
    borderRadius: 18,
  },
});
