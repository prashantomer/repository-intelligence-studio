"""
Build: Repository Intelligence Studio — polished presentation
"""
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.util import Pt
import copy

# ── Palette ────────────────────────────────────────────────────────────────
NAVY      = RGBColor(0x14, 0x24, 0x3D)   # deep navy  (backgrounds / headers)
TEAL      = RGBColor(0x0D, 0x9E, 0x8B)   # vibrant teal (accent)
TEAL_MID  = RGBColor(0x0B, 0x7A, 0x6C)   # darker teal (secondary accent)
SLATE     = RGBColor(0x4B, 0x5E, 0x7A)   # muted slate (body text on light)
OFFWHITE  = RGBColor(0xF4, 0xF7, 0xFA)   # near-white (slide bg)
WHITE     = RGBColor(0xFF, 0xFF, 0xFF)
CARD_BG   = RGBColor(0xEB, 0xF1, 0xF8)   # card fill
DIVIDER   = RGBColor(0xD0, 0xDC, 0xEC)   # thin rule
HIGHLIGHT = RGBColor(0xE8, 0xF5, 0xF2)   # teal-tinted card
YELLOW    = RGBColor(0xFF, 0xC1, 0x07)   # warm accent for caution / flow

# ── Dimensions (widescreen 16:9) ────────────────────────────────────────────
W = Inches(13.33)
H = Inches(7.5)

prs = Presentation()
prs.slide_width  = W
prs.slide_height = H

BLANK = prs.slide_layouts[6]   # truly blank

# ══════════════════════════════════════════════════════════════════════════════
# Helper utilities
# ══════════════════════════════════════════════════════════════════════════════

def add_rect(slide, l, t, w, h, fill=None, line=None, line_w=Pt(0)):
    from pptx.util import Emu
    shape = slide.shapes.add_shape(1, l, t, w, h)  # MSO_SHAPE_TYPE.RECTANGLE = 1
    shape.line.width = line_w
    if fill:
        shape.fill.solid()
        shape.fill.fore_color.rgb = fill
    else:
        shape.fill.background()
    if line:
        shape.line.color.rgb = line
    else:
        shape.line.fill.background()
    return shape

def add_text(slide, text, l, t, w, h,
             size=Pt(14), bold=False, color=NAVY,
             align=PP_ALIGN.LEFT, wrap=True, italic=False):
    txb = slide.shapes.add_textbox(l, t, w, h)
    tf  = txb.text_frame
    tf.word_wrap = wrap
    p   = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.size  = size
    run.font.bold  = bold
    run.font.color.rgb = color
    run.font.italic = italic
    return txb

def add_para(tf, text, size=Pt(13), bold=False, color=NAVY,
             align=PP_ALIGN.LEFT, space_before=Pt(4), italic=False):
    from pptx.oxml.ns import qn
    from lxml import etree
    p   = tf.add_paragraph()
    p.alignment = align
    p.space_before = space_before
    run = p.add_run()
    run.text = text
    run.font.size  = size
    run.font.bold  = bold
    run.font.color.rgb = color
    run.font.italic = italic
    return p

def slide_bg(slide, color=OFFWHITE):
    """Fill slide background."""
    bg = slide.background
    fill = bg.fill
    fill.solid()
    fill.fore_color.rgb = color

def add_accent_bar(slide, color=TEAL, t=Inches(0), h=Inches(0.06)):
    """Full-width thin bar at the top."""
    add_rect(slide, 0, t, W, h, fill=color)

def add_label_chip(slide, text, l, t, w=Inches(2.2), h=Inches(0.36),
                   bg=TEAL, fg=WHITE, size=Pt(10)):
    add_rect(slide, l, t, w, h, fill=bg)
    txb = slide.shapes.add_textbox(l, t + Inches(0.02), w, h)
    tf  = txb.text_frame
    tf.word_wrap = False
    p   = tf.paragraphs[0]
    p.alignment = PP_ALIGN.CENTER
    run = p.add_run()
    run.text = text.upper()
    run.font.size  = size
    run.font.bold  = True
    run.font.color.rgb = fg

# ══════════════════════════════════════════════════════════════════════════════
# SLIDE 1 — COVER
# ══════════════════════════════════════════════════════════════════════════════
def slide_cover():
    slide = prs.slides.add_slide(BLANK)
    slide_bg(slide, NAVY)

    # Teal left accent panel
    add_rect(slide, 0, 0, Inches(0.55), H, fill=TEAL)

    # Decorative circle top-right
    circ = slide.shapes.add_shape(9, W - Inches(2.8), -Inches(0.6), Inches(3.4), Inches(3.4))
    circ.fill.solid(); circ.fill.fore_color.rgb = RGBColor(0x1C, 0x36, 0x5C)
    circ.line.fill.background()

    # Tagline chip
    add_label_chip(slide, "Capstone MVP  ·  Feature Walkthrough",
                   Inches(0.85), Inches(1.6), w=Inches(4.2), bg=TEAL_MID, size=Pt(10))

    # Title
    add_text(slide,
             "Repository\nIntelligence Studio",
             Inches(0.85), Inches(2.05), Inches(9), Inches(2.4),
             size=Pt(52), bold=True, color=WHITE, align=PP_ALIGN.LEFT)

    # Subtitle
    add_text(slide,
             "Unified ingestion · semantic search · AI assistant · change impact analysis",
             Inches(0.85), Inches(4.55), Inches(9.5), Inches(0.5),
             size=Pt(17), color=RGBColor(0xA8, 0xC4, 0xDC), align=PP_ALIGN.LEFT)

    # Bottom rule + date
    add_rect(slide, Inches(0.85), Inches(6.75), Inches(11.6), Inches(0.03), fill=TEAL_MID)
    add_text(slide, "June 2026",
             Inches(0.85), Inches(6.85), Inches(3), Inches(0.4),
             size=Pt(11), color=RGBColor(0x70, 0x90, 0xB0))

slide_cover()

# ══════════════════════════════════════════════════════════════════════════════
# SLIDE 2 — FEATURE OVERVIEW (table of contents)
# ══════════════════════════════════════════════════════════════════════════════
FEATURES = [
    ("01", "Repository Creation & Ingestion",
     "Register a repo, clone it, and build the full indexed knowledge base."),
    ("02", "Manual Re-Sync",
     "Refresh the knowledge base on demand from the tracked branch."),
    ("03", "Repository Assistant",
     "Ask natural-language questions; get answers grounded in your codebase."),
    ("04", "Semantic Search",
     "Retrieve the most relevant code or documentation chunks by meaning."),
    ("05", "Impact Analyzer",
     "Understand upstream and downstream blast radius before making changes."),
    ("06", "Provider Logs",
     "Inspect every AI call — model, latency, token usage, and estimated cost."),
    ("07", "Centralized AI Settings",
     "Configure provider, model, and embedding behavior from one screen."),
]

def slide_overview():
    slide = prs.slides.add_slide(BLANK)
    slide_bg(slide, OFFWHITE)
    add_accent_bar(slide, TEAL)

    # Section label
    add_label_chip(slide, "Feature Overview", Inches(0.5), Inches(0.18),
                   w=Inches(2.0), h=Inches(0.3), bg=TEAL, size=Pt(9))

    add_text(slide, "What This System Does",
             Inches(0.5), Inches(0.55), Inches(12), Inches(0.6),
             size=Pt(28), bold=True, color=NAVY)

    add_text(slide,
             "Seven features delivered in the MVP — covering the full engineering knowledge lifecycle.",
             Inches(0.5), Inches(1.1), Inches(12), Inches(0.4),
             size=Pt(13), color=SLATE)

    # Two-column grid
    cols = 2
    card_w = Inches(6.0)
    card_h = Inches(0.76)
    pad_x  = Inches(0.5)
    gap_x  = Inches(0.5)
    start_y = Inches(1.65)
    gap_y   = Inches(0.1)

    for idx, (num, title, desc) in enumerate(FEATURES):
        col = idx % cols
        row = idx // cols
        lx = pad_x + col * (card_w + gap_x)
        ty = start_y + row * (card_h + gap_y)

        # card background
        add_rect(slide, lx, ty, card_w, card_h, fill=WHITE,
                 line=DIVIDER, line_w=Pt(0.8))

        # number pill
        add_rect(slide, lx, ty, Inches(0.55), card_h, fill=TEAL)
        add_text(slide, num,
                 lx, ty + Inches(0.17), Inches(0.55), Inches(0.4),
                 size=Pt(13), bold=True, color=WHITE, align=PP_ALIGN.CENTER)

        # feature title
        add_text(slide, title,
                 lx + Inches(0.65), ty + Inches(0.06), card_w - Inches(0.75), Inches(0.32),
                 size=Pt(13), bold=True, color=NAVY)

        # description
        add_text(slide, desc,
                 lx + Inches(0.65), ty + Inches(0.38), card_w - Inches(0.75), Inches(0.34),
                 size=Pt(10.5), color=SLATE)

slide_overview()

# ══════════════════════════════════════════════════════════════════════════════
# Generic feature slide builder
# ══════════════════════════════════════════════════════════════════════════════
def feature_slide(num, title, subtitle,
                  inputs, processing, outputs, flow):

    slide = prs.slides.add_slide(BLANK)
    slide_bg(slide, OFFWHITE)
    add_accent_bar(slide, TEAL)

    # Feature number badge
    add_label_chip(slide, f"Feature {num}", Inches(0.5), Inches(0.18),
                   w=Inches(1.55), h=Inches(0.3), bg=TEAL, size=Pt(9))

    # Title
    add_text(slide, title,
             Inches(0.5), Inches(0.55), Inches(12.3), Inches(0.55),
             size=Pt(26), bold=True, color=NAVY)

    # Subtitle
    add_text(slide, subtitle,
             Inches(0.5), Inches(1.08), Inches(12), Inches(0.38),
             size=Pt(12.5), color=SLATE, italic=True)

    # Thin rule
    add_rect(slide, Inches(0.5), Inches(1.48), Inches(12.3), Inches(0.025), fill=DIVIDER)

    # ── Three column cards ──────────────────────────────────────────────────
    card_w   = Inches(3.85)
    card_h   = Inches(4.45)
    start_x  = Inches(0.5)
    gap      = Inches(0.28)
    top      = Inches(1.6)

    sections = [
        ("Input",      inputs,      CARD_BG,   TEAL),
        ("Processing", processing,  HIGHLIGHT, TEAL_MID),
        ("Output",     outputs,     CARD_BG,   TEAL),
    ]

    for i, (label, bullets, bg, accent) in enumerate(sections):
        lx = start_x + i * (card_w + gap)

        # Card body
        add_rect(slide, lx, top, card_w, card_h, fill=bg, line=DIVIDER, line_w=Pt(0.6))

        # Accent top strip on card
        add_rect(slide, lx, top, card_w, Inches(0.05), fill=accent)

        # Section label
        add_text(slide, label,
                 lx + Inches(0.2), top + Inches(0.12), card_w - Inches(0.3), Inches(0.36),
                 size=Pt(12), bold=True, color=accent)

        # Bullets
        y_off = top + Inches(0.52)
        for bullet in bullets:
            txb = slide.shapes.add_textbox(lx + Inches(0.2), y_off,
                                           card_w - Inches(0.35), Inches(0.36))
            tf  = txb.text_frame
            tf.word_wrap = True
            p   = tf.paragraphs[0]
            run = p.add_run()
            run.text = f"›  {bullet}"
            run.font.size  = Pt(11.5)
            run.font.color.rgb = SLATE
            y_off += Inches(0.44)

    # ── Flow strip at bottom ────────────────────────────────────────────────
    flow_top = Inches(6.2)
    add_rect(slide, Inches(0.5), flow_top, Inches(12.3), Inches(0.85),
             fill=NAVY)
    add_text(slide, "  " + flow,
             Inches(0.55), flow_top + Inches(0.14), Inches(12.1), Inches(0.55),
             size=Pt(11), color=RGBColor(0xA8, 0xD0, 0xC8), italic=False, bold=False,
             align=PP_ALIGN.LEFT)

    # ── Page number ────────────────────────────────────────────────────────
    add_text(slide, str(int(num) + 2),
             W - Inches(0.65), H - Inches(0.4), Inches(0.5), Inches(0.35),
             size=Pt(10), color=SLATE, align=PP_ALIGN.CENTER)

# ══════════════════════════════════════════════════════════════════════════════
# Feature slides data
# ══════════════════════════════════════════════════════════════════════════════
SLIDES = [
    dict(
        num="01",
        title="Repository Creation & Initial Ingestion",
        subtitle="Register a repository and build its indexed, searchable knowledge base.",
        inputs=[
            "Repository name",
            "GitHub URL",
            "Default / tracked branch",
        ],
        processing=[
            "Create repository record",
            "Queue background ingestion job",
            "Clone source and inventory files",
            "Extract, chunk, and embed content",
            "Build dependency edges",
        ],
        outputs=[
            "Persisted repository record",
            "Indexed knowledge snapshot",
            "Ready for search, assistant & impact",
        ],
        flow="User  →  Registration Form  →  CreateService  →  IngestionJob  →  Clone  →  Parse  →  Chunk  →  Embed  →  Index",
    ),
    dict(
        num="02",
        title="Manual Re-Sync",
        subtitle="Refresh the repository knowledge base on demand from the tracked branch.",
        inputs=[
            "Repository selected",
            "User triggers Re-sync action",
        ],
        processing=[
            "Force-rebuild ingestion pipeline",
            "Recreate entities, chunks & embeddings",
            "Rebuild dependency edges",
            "Update status and sync history",
        ],
        outputs=[
            "Up-to-date indexed snapshot",
            "Refreshed ingestion history log",
        ],
        flow="User  →  Re-sync Action  →  StartService (force=true)  →  IngestionJob  →  Rebuilt Snapshot",
    ),
    dict(
        num="03",
        title="Repository Assistant",
        subtitle="Ask natural-language questions; receive answers grounded in indexed code and documentation.",
        inputs=[
            "Natural-language question",
            "Optional conversation history",
        ],
        processing=[
            "Queue question for async processing",
            "Retrieve most relevant chunks",
            "Construct grounded prompt",
            "Generate answer via provider or local model",
            "Stream response via Turbo frames",
        ],
        outputs=[
            "Grounded, cited answer",
            "Source file citations",
            "Persistent conversation history",
            "Provider usage log entry",
        ],
        flow="User  →  Ask Question  →  Queue  →  Retrieve Chunks  →  Build Prompt  →  LLM / Local Model  →  Stream to UI",
    ),
    dict(
        num="04",
        title="Semantic Search",
        subtitle="Locate the most relevant code and documentation chunks by meaning, not just keyword.",
        inputs=[
            "Natural-language search query",
        ],
        processing=[
            "Embed the query with the configured model",
            "Compare against stored chunk vectors",
            "Rank results by cosine similarity",
        ],
        outputs=[
            "Top-ranked matching chunks",
            "File paths and line ranges",
            "Chunk type context (function, class, doc…)",
        ],
        flow="User  →  Search Query  →  Query Embedding  →  Vector Similarity Match  →  Ranked Results",
    ),
    dict(
        num="05",
        title="Impact Analyzer",
        subtitle="Understand the blast radius of a change before it reaches production.",
        inputs=[
            "Entity name (class, method, file)",
            "Or a natural-language impact question",
        ],
        processing=[
            "Interpret the query and resolve the target",
            "Traverse the dependency graph",
            "Retrieve supporting evidence chunks",
            "Generate risk summary and action guidance",
        ],
        outputs=[
            "Risk level assessment",
            "Upstream & downstream dependencies",
            "Affected routes, jobs, and files",
            "Action checklist + saved analysis report",
        ],
        flow="Question  →  Interpreter  →  Entity Resolve  →  Graph Traversal  →  Evidence Retrieval  →  Impact Report",
    ),
    dict(
        num="06",
        title="Provider Logs",
        subtitle="Full visibility into every AI call — model, latency, tokens consumed, and estimated cost.",
        inputs=[
            "Assistant, embedding & impact narration calls",
        ],
        processing=[
            "Record provider, model, and operation type",
            "Capture token counts, latency, and status",
            "Calculate and store estimated cost",
        ],
        outputs=[
            "Chronological call log",
            "Debugging visibility for failed calls",
            "Usage and cost audit trail",
        ],
        flow="Feature Call  →  ProviderCallLogRecorder  →  Database Log Entry  →  Logs Dashboard",
    ),
    dict(
        num="07",
        title="Centralized AI Settings",
        subtitle="Control provider, model, and embedding configuration from a single settings screen.",
        inputs=[
            "Assistant provider and model selection",
            "Embedding provider and model selection",
            "Ollama base URL (for local inference)",
        ],
        processing=[
            "Persist user-level configuration",
            "Apply settings across all repository features",
        ],
        outputs=[
            "Consistent runtime configuration",
            "Assistant, search & impact inherit settings",
        ],
        flow="User  →  Settings Screen  →  Save Configuration  →  Runtime Features Inherit Config",
    ),
]

for s in SLIDES:
    feature_slide(**s)

# ══════════════════════════════════════════════════════════════════════════════
# SLIDE LAST — Closing
# ══════════════════════════════════════════════════════════════════════════════
def slide_closing():
    slide = prs.slides.add_slide(BLANK)
    slide_bg(slide, NAVY)

    add_rect(slide, 0, 0, Inches(0.55), H, fill=TEAL)

    # Large decorative circle
    circ = slide.shapes.add_shape(9,
                                  W - Inches(3.5), H - Inches(2.5),
                                  Inches(4.2), Inches(4.2))
    circ.fill.solid(); circ.fill.fore_color.rgb = RGBColor(0x1C, 0x36, 0x5C)
    circ.line.fill.background()

    add_text(slide, "Thank You",
             Inches(0.85), Inches(2.2), Inches(10), Inches(1.4),
             size=Pt(52), bold=True, color=WHITE)

    add_text(slide,
             "Repository Intelligence Studio  ·  MVP Feature Walkthrough  ·  June 2026",
             Inches(0.85), Inches(3.75), Inches(10), Inches(0.45),
             size=Pt(14), color=RGBColor(0xA8, 0xC4, 0xDC))

    add_rect(slide, Inches(0.85), Inches(4.35), Inches(4), Inches(0.04), fill=TEAL_MID)

slide_closing()

# ── Save ──────────────────────────────────────────────────────────────────────
out = "repository-intelligence-studio-v2.pptx"
prs.save(out)
print(f"Saved: {out}")
