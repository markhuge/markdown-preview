path = require 'path'
{WorkspaceView} = require 'atom'
MarkdownPreviewView = require '../lib/markdown-preview-view'

describe "MarkdownPreviewView", ->
  [file, preview] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    atom.workspace = atom.workspaceView.model

    filePath = atom.project.resolve('subdir/file.markdown')
    preview = new MarkdownPreviewView({filePath})

    waitsForPromise ->
      atom.packages.activatePackage('language-ruby')

  afterEach ->
    preview.destroy()

  describe "::constructor", ->
    it "shows a loading spinner and renders the markdown", ->
      preview.showLoading()
      expect(preview.find('.markdown-spinner')).toExist()

      waitsForPromise ->
        preview.renderMarkdown()

      runs ->
        expect(preview.find(".emoji")).toExist()

    it "shows an error message when there is an error", ->
      preview.showError("Not a real file")
      expect(preview.text()).toContain "Failed"

  describe "serialization", ->
    newPreview = null

    afterEach ->
      newPreview.destroy()

    it "recreates the file when serialized/deserialized", ->
      newPreview = atom.deserializers.deserialize(preview.serialize())
      expect(newPreview.getPath()).toBe preview.getPath()

    it "serializes the editor id when opened for an editor", ->
      preview.destroy()

      waitsForPromise ->
        atom.workspace.open('new.markdown')

      runs ->
        preview = new MarkdownPreviewView({editorId: atom.workspace.getActiveEditor().id})
        expect(preview.getPath()).toBe atom.workspace.getActiveEditor().getPath()

        newPreview = atom.deserializers.deserialize(preview.serialize())
        expect(newPreview.getPath()).toBe preview.getPath()

  describe "code block tokenization", ->
    beforeEach ->
      waitsForPromise ->
        preview.renderMarkdown()

    describe "when the code block's fence name has a matching grammar", ->
      it "tokenizes the code block with the grammar", ->
        expect(preview.find("pre span.entity.name.function.ruby")).toExist()

    describe "when the code block's fence name doesn't have a matching grammar", ->
      it "does not tokenize the code block", ->
        expect(preview.find("pre code:not([class])").children().length).toBe 0
        expect(preview.find("pre code.lang-kombucha").children().length).toBe 0

  describe "image resolving", ->
    beforeEach ->
      waitsForPromise ->
        preview.renderMarkdown()

    describe "when the image uses a relative path", ->
      it "resolves to a path relative to the file", ->
        image = preview.find("img[alt=Image1]")
        expect(image.attr('src')).toBe atom.project.resolve('subdir/image1.png')

    describe "when the image uses an absolute path", ->
      it "doesn't change the path", ->
        image = preview.find("img[alt=Image2]")
        expect(image.attr('src')).toBe '/tmp/image2.png'

    describe "when the image uses a web URL", ->
      it "doesn't change the URL", ->
        image = preview.find("img[alt=Image3]")
        expect(image.attr('src')).toBe 'http://github.com/image3.png'

  describe "gfm newlines", ->
    describe "when gfm newlines are not enabled", ->
      it "creates a single paragraph with <br>", ->
        atom.config.set('markdown-preview.breakOnSingleNewline', false)

        waitsForPromise ->
          preview.renderMarkdown()

        runs ->
          expect(preview.find("p:last-child br").length).toBe 0

    describe "when gfm newlines are enabled", ->
      it "creates a single paragraph with no <br>", ->
        atom.config.set('markdown-preview.breakOnSingleNewline', true)

        waitsForPromise ->
          preview.renderMarkdown()

        runs ->
          expect(preview.find("p:last-child br").length).toBe 1
