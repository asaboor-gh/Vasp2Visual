---
customTheme : "myserif"
transition: "slide"
highlightTheme: "monokai"
logoImg: "./ud.png"
slideNumber: false
enableTitleFooter: false
enableChalkboard: true
enableMenu: true
title: "VSCode Reveal intro"
---

## Markdown Slides
:::block
Let's have fun with [**reveal.js**](https://github.com/hakimel/reveal.js/) and [**vscode-reveal**](https://github.com/evilz/vscode-reveal) extension for VSCode. You can also get a LATEX Beamer template [**Beamer-Timer**](https://github.com/massgh/Beamer-Timer). Both reveal.js and Beamer-Timer are included in [**Vasp2Visual**](https://github.com/massgh/Vasp2Visual). {style=background:cyan;width:95%}
::: 

---

### Two-Columns
<div class="row">
  <div class="column-r">
   <p>
   This is two column slide with 6:4 widths ratio. It should be created using HTML itself. Two column environment is modified in custom theme.
   </p>
  </div>
  <div class="column-l">
<a href="#/2">
    <image width=70% data-src="./ud.png" alt="Up arrow">
</a>
  </div>
</div>

```html
<div class="row">
  <div class="column-r"><p>This is two column slide with 6:4 widths ratio. It should be created using HTML itself. Two column environment is modified in custom theme.</p></div>
  <div class="column-l"> <a href="#/2">
    <image width=70% data-src="./ud.png" alt="Up arrow">
  </a></div>
</div>
```

---

## Table                             

First header | Second header
-------------|---------------
List:        | More  \
- over       | data  \
- several    |       
----------------------------

First header | Second header
-------------|---------------
Merged       | Cell 1
^^           | Cell 2
Seperate       | Cell 3
[New Table]
----------

---

## vscode-reveal

 Awesome VS code extension using The HTML Presentation Framework Revealjs

Created by [Vincent B.](https://www.evilznet.com) / [@Evilznet](https://twitter.com/Evilznet)


---

## See More on [Reveal](https://revealjs.com/)
<iframe data-src="https://revealjs.com/" width=70% height="355" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:3px solid #666; margin-bottom:5px; max-width: 100%;" allowfullscreen=""></iframe>
   
---

### Tabular Tables and Quotes
<q>Inline quotes </q> and block quotes

>| Tables        | Are           | Cool  |
>|-------------|:-----------:|----:|
>| col 3 is      | right-aligned | $1600 |
>| col 2 is      | centered      | $12   |


### Intergalactic Interconnections

You can link between slides internally, **[like this](#/2/3)**.

---

## Plugins

### Search

Handles finding a text string anywhere in the slides and showing the next occurrence to the user by navigatating to that slide and highlighting it.

**Shortcut : `CTRL + SHIFT + F`**

--

### Zoom

Zoom anywhere on your presentation

**Shortcut : `alt + click`: Zoom in. Repeat to zoom back out.**

## Notes

Add note to speaker view.

Default markdown syntaxe is

```text
note: a custom note here
```
note: a custom note here
--

## Chalkboard

Have you ever missed the traditional classroom experience where you can quickly sketch something on a chalkboard?

Just press 'b' or click on the pencil button to open and close your chalkboard.

--

## Chalkboard

- Click the `left mouse button` to write on the chalkboard
- Click the `right mouse button` to wipe the chalkboard
- Click the `DEL` key to clear the chalkboard

--

## MAKE NOTES ON SLIDES

Did you notice the <i class="fa fa-pencil"></i> button?

By pressing 'c' or clicking the button you can start and stop the notes taking mode allowing you to write comments and notes directly on the slide.

--

## Chart

Add chart from simple string

--

### Line chart from JSON string
<canvas class="stretch" data-chart="line">
<!--
{
 "data": {
  "labels": ["January"," February"," March"," April"," May"," June"," July"],
  "datasets":[
   {
    "data":[65,59,80,81,56,55,40],
    "label":"My first dataset","backgroundColor":"rgba(20,220,220,.8)"
   },
   {
    "data":[28,48,40,19,86,27,90],
    "label":"My second dataset","backgroundColor":"rgba(220,120,120,.8)"
   }
  ]
 }, 
 "options": { "responsive": "true" }
}
-->
</canvas>

--

### Line chart with CSV data and JSON configuration

<canvas class="stretch" data-chart="line">
My first dataset,  65, 59, 80, 81, 56, 55, 40
<!-- This is a comment -->
My second dataset, 28, 48, 40, 19, 86, 27, 90
<!-- 
{ 
"data" : {
	"labels" : ["Enero", "Febrero", "Marzo", "Avril", "Mayo", "Junio", "Julio"],
	"datasets" : [{ "borderColor": "#0f0", "borderDash": ["5","10"] }, { "borderColor": "#0ff" } ]
	}
}
-->
</canvas>

--

### Bar chart with CSV data

<canvas class="stretch" data-chart="bar">
,January, February, March, April, May, June, July
My first dataset, 65, 59, 80, 81, 56, 55, 40
My second dataset, 28, 48, 40, 19, 86, 27, 90
</canvas>

--

### Stacked bar chart from CSV file with JSON configuration
<canvas class="stretch" data-chart="bar" data-chart-src="https://rajgoel.github.io/reveal.js-demos/chart/data.csv">
<!-- 
{
"data" : {
"datasets" : [{ "backgroundColor": "#0f0" }, { "backgroundColor": "#0ff" } ]
},
"options": { "responsive": true, "scales": { "xAxes": [{ "stacked": true }], "yAxes": [{ "stacked": true }] } }
}
-->
</canvas>

--

### Pie chart

<canvas class="stretch" data-chart="pie">
,Black, Red, Green, Yellow
My first dataset, 40, 40, 20, 6
My second dataset, 45, 40, 25, 4
</canvas>

--

## EMBEDDING A TWEET
To embed a tweet, simply determine its URL and include the following code in your slides:

```html
<div class="tweet" data-src="TWEET_URL"></div>
```

<div class="tweet"  data-src="https://twitter.com/Evilznet/status/1086984843056107525"></div>

--

## menu

A SLIDEOUT MENU FOR NAVIGATING REVEAL.JS PRESENTATIONS


See the  <i class="fa fa-bars"></i>  in the corner?

Click it and the menu will open from the side.

Click anywhere on the slide to return to the presentation,
or use the close button in the menu.

--

If you don't like the menu button,
you can use the slide number instead.

Go on, give it a go.

The menu button can be hidden using the options, 
but you need to enable the slide number link.

--

Or you can open the menmu by pressing the m key.

You can navigate the menu with the keyboard as well. 
Just use the arrow keys and <space> or <enter> to change slides.

You can disable the keyboard for the 
menu in the options if you wish.

--

## LEFT OR RIGHT
You can configure the menu to slide in from the left or right

### MARKERS
The slide markers in the menu can be useful to show 
you the progress through the presentation.

You can hide them if you want.

You can also show/hide slide numbers.

--

### SLIDE TITLES
The menu uses the first heading to label each slide
but you can specify another label if you want.

Use a data-menu-title attribute in the section element to give the slide a custom label, or add a menu-title class to any element in the slide you wish.

You can change the titleSelector option and use
any elements you like as the default for labelling each slide.

--

## MathSVG

An extension of the math.js plugin allowing to render LaTeX in SVG.

--

### The Lorenz Equations

<span>
\[\begin{aligned}
\dot{x} &amp; = \sigma(y-x) \\
\dot{y} &amp; = \rho x - y - xz \\
\dot{z} &amp; = -\beta z + xy
\end{aligned} \]
</span>

--

### The Cauchy-Schwarz Inequality

<script type="math/tex; mode=display">
  \left( \sum_{k=1}^n a_k b_k \right)^2 \leq \left( \sum_{k=1}^n a_k^2 \right) \left( \sum_{k=1}^n b_k^2 \right)
</script>

--

### Custom footer

Includes a footer in all the slides of a Reveal.js presentation (with optional exclusion of some slides) that will show the title of the presentation.

## code-focus

A plugin that allows focusing on specific lines of code blocks.

--

### Code Focus Demo

```html
<section>
  <pre><code>
  // Useless comment.
  alert('hi');
  </pre></code>
  <p class="fragment" data-code-focus="1">
    This focuses on the comment.
  </p>
  <p class="fragment" data-code-focus="1-2">
    Another fragment.
  </p>
</section>
```

This section is a slide. {.fragment .current-only data-code-focus=1-12}

This will be highlighted by `highlight.js`. {.fragment .current-only data-code-focus=2-5}

This fragment focuses on the first line. {.fragment .current-only data-code-focus=6-8}

This fragment focuses on lines 1 and 2. {.fragment .current-only data-code-focus=9-11}

See the next slide for a demo with the contents of this code block. {.fragment .current-only data-code-focus=1-12}

---

<!-- .slide: style="text-align: center;" -->
# THE END

- [Try the online editor](http://slides.com)
- [Source code & documentation](https://github.com/hakimel/reveal.js)