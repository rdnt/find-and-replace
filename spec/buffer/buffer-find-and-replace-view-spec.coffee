$ = require 'jquery'
RootView = require 'root-view'

describe 'BufferFindAndReplaceView', ->
  [editor, bufferFindAndReplaceView] = []

  beforeEach ->
    window.rootView = new RootView()
    rootView.open('sample.js')
    rootView.enableKeymap()
    rootView.attachToDom()
    editor = rootView.getActiveView()
    pack = atom.activatePackage("find-and-replace")
    bufferFindAndReplaceView = pack.mainModule.bufferFindAndReplaceView

  describe "when find-and-replace:display-find is triggered", ->
    it "attaches BufferFindAndReplaceView to the root view", ->
      editor.trigger 'find-and-replace:display-find'
      expect(rootView.find('.find-and-replace')).toExist()

  describe "when core:cancel is triggered", ->
    it "detaches from the root view", ->
      editor.trigger 'find-and-replace:display-find'
      $(document.activeElement).trigger 'core:cancel'
      expect(rootView.find('.find-and-replace')).not.toExist()

  describe "finding", ->
    beforeEach ->
      editor.setCursorBufferPosition([2,0])
      editor.trigger 'find-and-replace:display-find'
      bufferFindAndReplaceView.findEditor.setText 'items'
      $(document.activeElement).trigger 'core:confirm'

    it "selects the first match following the cursor", ->
      expect(bufferFindAndReplaceView.resultCounter.text()).toEqual('2 of 6')
      expect(editor.getSelectedBufferRange()).toEqual [[2, 8], [2, 13]]

    it "selects the next match when the next match button is pressed", ->
      $('.find-and-replace .icon-next').click()
      expect(bufferFindAndReplaceView.resultCounter.text()).toEqual('3 of 6')
      expect(editor.getSelectedBufferRange()).toEqual [[2, 34], [2, 39]]

    it "selects the next match when the 'find-and-replace:focus-next' event is triggered", ->
      editor.trigger('find-and-replace:find-next')
      expect(bufferFindAndReplaceView.resultCounter.text()).toEqual('3 of 6')
      expect(editor.getSelectedBufferRange()).toEqual [[2, 34], [2, 39]]

    it "selects the previous match when the previous match button is pressed", ->
      $('.find-and-replace .icon-previous').click()
      expect(bufferFindAndReplaceView.resultCounter.text()).toEqual('1 of 6')
      expect(editor.getSelectedBufferRange()).toEqual [[1, 27], [1, 22]]

    it "selects the previous match when the 'find-and-replace:focus-previous' event is triggered", ->
      editor.trigger('find-and-replace:find-previous')
      expect(bufferFindAndReplaceView.resultCounter.text()).toEqual('1 of 6')
      expect(editor.getSelectedBufferRange()).toEqual [[1, 27], [1, 22]]

    it "replaces results counter with number of results found when user moves cursor outside a marker", ->
      editor.moveCursorDown()
      expect(bufferFindAndReplaceView.resultCounter.text()).toBe '6 found'
      editor.moveCursorUp()
      expect(bufferFindAndReplaceView.resultCounter.text()).toBe '2 of 6'

    describe "when the active editor changes", ->
      it "detaches the view when there are no more active editors", ->
        editor.trigger 'core:close'
        expect(rootView.find('.find-and-replace')).not.toExist()

  describe "replacing", ->
    beforeEach ->
      editor.setCursorBufferPosition([2,0])
      editor.trigger 'find-and-replace:display-replace'
      bufferFindAndReplaceView.findEditor.setText('items')
      bufferFindAndReplaceView.replaceEditor.setText('cats')

    describe "replace next", ->
      describe "when core:confirm is triggered", ->
        it "replaces the match after the cursor and selects the next match", ->
          bufferFindAndReplaceView.replaceEditor.trigger 'core:confirm'
          expect(bufferFindAndReplaceView.resultCounter.text()).toEqual('2 of 5')
          expect(editor.lineForBufferRow(2)).toBe "    if (cats.length <= 1) return items;"
          expect(editor.getSelectedBufferRange()).toEqual [[2, 33], [2, 38]]

      describe "when the replace next button is pressed", ->
        it "replaces the match after the cursor and selects the next match", ->
          $('.find-and-replace .btn-next').click()
          expect(bufferFindAndReplaceView.resultCounter.text()).toEqual('2 of 5')
          expect(editor.lineForBufferRow(2)).toBe "    if (cats.length <= 1) return items;"
          expect(editor.getSelectedBufferRange()).toEqual [[2, 33], [2, 38]]

      describe "when the 'find-and-replace:replace-next' event is triggered", ->
        it "replaces the match after the cursor and selects the next match", ->
          editor.trigger 'find-and-replace:replace-next'
          expect(bufferFindAndReplaceView.resultCounter.text()).toEqual('2 of 5')
          expect(editor.lineForBufferRow(2)).toBe "    if (cats.length <= 1) return items;"
          expect(editor.getSelectedBufferRange()).toEqual [[2, 33], [2, 38]]

    describe "replace all", ->
      describe "when the replace all button is pressed", ->
        it "replaces the match after the cursor and selects the next match", ->
          $('.find-and-replace .btn-all').click()
          expect(bufferFindAndReplaceView.resultCounter.text()).toEqual('0 found')
          expect(editor.getText()).not.toMatch /items/
          expect(editor.getSelectedBufferRange()).toEqual [[2, 0], [2, 0]]

      describe "when the 'find-and-replace:replace-next' event is triggered", ->
        it "replaces the match after the cursor and selects the next match", ->
          editor.trigger 'find-and-replace:replace-all'
          expect(bufferFindAndReplaceView.resultCounter.text()).toEqual('0 found')
          expect(editor.getText()).not.toMatch /items/
          expect(editor.getSelectedBufferRange()).toEqual [[2, 0], [2, 0]]

  describe "history", ->
    beforeEach ->
      editor.trigger 'find-and-replace:display-find'
      bufferFindAndReplaceView.searchModel.setPattern('one')
      bufferFindAndReplaceView.searchModel.setPattern('two')
      bufferFindAndReplaceView.searchModel.setPattern('three')

      expect(bufferFindAndReplaceView.searchModel.history.length).toEqual 3
      expect(bufferFindAndReplaceView.searchModel.historyIndex).toEqual 2

    it "can navigate the entire history stack", ->
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'three'

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-previous-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'two'

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-previous-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'one'

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-previous-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'one'

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-next-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'two'

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-next-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'three'

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-next-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual ''

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-next-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual ''

    it "maintains current unsearched text in the history", ->
      text = 'something I want to search for but havent yet'
      bufferFindAndReplaceView.findEditor.setText(text)

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-previous-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'two'

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-next-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'three'

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-next-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual text

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-next-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual text

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-previous-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'three'

    it "adds confirmed patterns to the history", ->
      bufferFindAndReplaceView.findEditor.setText("cool stuff")
      bufferFindAndReplaceView.findEditor.trigger 'core:confirm'

      bufferFindAndReplaceView.findEditor.setText("cooler stuff")
      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-previous-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'cool stuff'

      bufferFindAndReplaceView.findEditor.trigger 'find-and-replace:search-previous-in-history'
      expect(bufferFindAndReplaceView.findEditor.getText()).toEqual 'three'
