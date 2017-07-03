
editorState = new WeakMap()

module.exports =
  activate: (state) ->
    atom.commands.add "atom-text-editor",
        "center-line:toggle": () => @toggle()

  toggle: ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor?
      return

    # Get the cursor position and screen boundaries
    cursor = editor.getCursorScreenPosition()
    view = atom.views.getView(editor);

    rows =
      first: view.getFirstVisibleScreenRow()
      last: view.getLastVisibleScreenRow()
      cursor: cursor.row
      final: editor.getLastScreenRow()

    rows.center = rows.first + Math.round((rows.last - rows.first) / 2) - 1

    if rows.first is 0 and rows.last is rows.final
      return

    # Figure out where we are and where we want to go.
    here = editorState.get(editor) or 'other';

    cycles =
      center: 'first'
      first:  'last'
      last:   'center'
      other:  'center'
    goto = cycles[here]

    # Now go.  We'll scroll ourselves since EditorView.scrollVertically seems to have a bug and
    # does not scroll if the requested pixel is already on the screen.

    pixel = view.pixelPositionForScreenPosition(cursor).top

    if goto is 'center'
      pixel -= (view.getHeight() / 2);
    else if goto is 'last'
      # Back up two lines since the scrollbar height doesn't seem to be accounted
      # for in scrollView.height.  Make sure slack is at last one
      averageLineHeight = view.getHeight() / (rows.last - rows.first);
      pixel -= view.getHeight() - averageLineHeight * 2

    view.setScrollTop pixel
    editorState.set editor, goto

    disposable = editor.onDidChangeCursorPosition =>
        console.log 'dispose'
        editorState.delete editor
        disposable.dispose()
