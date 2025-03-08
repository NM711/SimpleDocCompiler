import ../lib/SimpleDocParser/src/parser
import ../lib/SimpleDocParser/src/node
import std/tables

type Compiler* = ref object
  source: string

method accept(self: Node, visitor: Compiler): void {.base.}

proc openTag(self: Compiler, element: string): void =
  self.source &= "<" & element & ">"

proc openTag(self: Compiler, element: string, attributes: Table[string, string]): void =
  self.source &= "<" & element

  if attributes.len() > 0:
    self.source &= " "
  
    for key, value in attributes:
    
    
      self.source &= key
    
      if value.len() > 0:
        self.source &= " = " & "\"" & value & "\""
    
  self.source &= ">" 

proc closeTag(self: Compiler, element: string): void = 
  self.source &= "</" & element & ">"

proc visit(self: Compiler, node: Node): void =
  discard

proc visit(self: Compiler, node: ValueNode): void =
  self.source &= node.value
  
proc visit(self: Compiler, node: BodyNode): void =
  var element = case node.kind:
    of NodeKind.PARAGRAPH:
      "p"
    else:
      "figcaption"
  
  self.openTag(element)

  for n in node.body:
    n.accept(self)

  self.closeTag(element)
  
proc visit(self: Compiler, node: HeaderNode): void =
  var element = "h" & $node.depth
  
  self.openTag(element)
  
  for n in node.body:
    n.accept(self)
    
  self.closeTag(element)

proc visit(self: Compiler, node: ListItemNode): void =
  case node.itemType:
    of ListItemType.UNORDERED, ListItemType.ORDERED:
      self.openTag("li")
      
      for n in node.body:
        n.accept(self)
      
      self.closeTag("li")
   
    of ListItemType.CHECKED:
      self.openTag("label")

      for n in node.body:
        n.accept(self)
        
      self.closeTag("label")
      
      var attributes: Table[string, string] 

      if node.isChecked:
        attributes["checked"] = ""

      if not node.isInteractive:
        attributes["disabled"] = ""

      self.openTag("input")

proc visit(self: Compiler, node: ListNode): void =
  var item = node.items[0]

  var element: string

  case item.itemType:
    of ListItemType.UNORDERED:
      element = "ul"
      self.openTag(element)
    of ListItemType.ORDERED:
      element = "ol"
      self.openTag(element, {"start": $item.number}.toTable())
    of ListItemType.CHECKED:
      element = "div"
      self.openTag(element)
  
  for n in node.items:
    n.accept(self)

  self.closeTag(element)
  
proc visit(self: Compiler, node: EmphasisNode): void =
  if node.kind == NodeKind.BOLD_ITALIC:
    self.openTag("b")
    self.openTag("i")
    node.value.accept(self)
    self.closeTag("i")
    self.closeTag("b")
  else:
    var element = case node.kind:
      of NodeKind.ITALIC:
        "i"
      else:
        "b"
    self.openTag(element)
    node.value.accept(self)
    self.closeTag(element)
    
proc visit(self: Compiler, node: LinkNode): void =
  self.openTag("a", {"href": node.href}.toTable())
  node.content.accept(self)
  self.closeTag("a")

proc visit(self: Compiler, node: ImageNode): void =
  self.openTag("img", {"alt": node.alt, "src": node.src}.toTable())
  node.caption.accept(self)  
  self.closeTag("img")
  
proc visit(self: Compiler, node: CodeBlockNode): void =
  self.openTag("pre")
  self.openTag("code")

  for c in node.content:
    case c:
      of '<':
        self.source &= "&lt;"
      of '>':
        self.source &= "&gt;"
      else:
        self.source &= c
  
  self.closeTag("code")
  self.closeTag("pre")

proc visit(self: Compiler, node: MetaNode): void =
  self.openTag("head")

  for key, value in node.data.pairs():
    case key:
      of "title":
        self.openTag("title")
        self.source &= value
        self.closeTag("title")
      else:
        self.openTag("media", { "name": key, "content": value }.toTable())

  self.closeTag("head")

method accept(self: Node, visitor: Compiler): void {.base.} =
  visitor.visit(self)

method accept(self: ValueNode, visitor: Compiler): void =
  visitor.visit(self)

method accept(self: BodyNode, visitor: Compiler): void =
  visitor.visit(self)
  
method accept(self: HeaderNode, visitor: Compiler): void =
  visitor.visit(self)

method accept(self: ListItemNode, visitor: Compiler): void =
  visitor.visit(self)

method accept(self: ListNode, visitor: Compiler): void =
  visitor.visit(self)

method accept(self: LinkNode, visitor: Compiler): void =
  visitor.visit(self)

method accept(self: ImageNode, visitor: Compiler): void =
  visitor.visit(self)

method accept(self: EmphasisNode, visitor: Compiler): void =
  visitor.visit(self)

method accept(self: CodeBlockNode, visitor: Compiler): void =
  visitor.visit(self)

method accept(self: MetaNode, visitor: Compiler): void =
  visitor.visit(self)

proc compile*(self: Compiler, path: string): string =
  self.source = "<!DOCTYPE html>"
  self.openTag("html")

  var sdparser = Parser()
  sdparser.setPath(path)
  sdparser.execute()

  var isBodyStart = true

  for node in sdparser.getNodes():

    if node.kind != NodeKind.META and isBodyStart:
      self.openTag("body")
      isBodyStart = false

    node.accept(self)
  self.closeTag("body")
  self.closeTag("html")

  var tmp = self.source
  self.source = ""
  return tmp
