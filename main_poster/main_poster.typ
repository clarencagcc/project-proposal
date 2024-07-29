// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}


#let poster(
  // The poster's size.
  size: "'36x24' or '48x36''",

  // The poster's title.
  title: "Paper Title",

  // A string of author names.
  authors: "Author Names (separated by commas)",

  // Department name.
  departments: "",

  // University logo.
  univ_logo: "Logo Path",

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
  footer_text: "Footer Text",

  // Any URL, like a link to the conference website.
  footer_url: "Footer URL",

  // Email IDs of the authors.
  footer_email_ids: "Email IDs (separated by commas)",

  // Color of the footer.
  footer_color: "Hex Color Code",

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  keywords: (),

  // Number of columns in the poster.
  num_columns: "3",

  // University logo's scale (in %).
  univ_logo_scale: "100",

  // University logo's column size (in in).
  univ_logo_column_size: "10",

  // Title and authors' column size (in in).
  title_column_size: "20",

  // Poster title's font size (in pt).
  title_font_size: "48",

  // Authors' font size (in pt).
  authors_font_size: "36",

  // Footer's URL and email font size (in pt).
  footer_url_font_size: "30",

  // Footer's text font size (in pt).
  footer_text_font_size: "40",

  // The poster's content.
  body
) = {
  // Set the body font.
  set text(font: "STIX Two Text", size: 16pt)
  let sizes = size.split("x")
  let width = int(sizes.at(0)) * 1in
  let height = int(sizes.at(1)) * 1in
  univ_logo_scale = int(univ_logo_scale) * 1%
  title_font_size = int(title_font_size) * 1pt
  authors_font_size = int(authors_font_size) * 1pt
  num_columns = int(num_columns)
  univ_logo_column_size = int(univ_logo_column_size) * 1in
  title_column_size = int(title_column_size) * 1in
  footer_url_font_size = int(footer_url_font_size) * 1pt
  footer_text_font_size = int(footer_text_font_size) * 1pt

  // Configure the page.
  // This poster defaults to 36in x 24in.
  set page(
    width: width,
    height: height,
    margin: 
      (top: 1in, left: 2in, right: 2in, bottom: 2in),
    footer: [
      #set align(center)
      #set text(32pt)
      #block(
        fill: rgb(footer_color),
        width: 100%,
        inset: 20pt,
        radius: 10pt,
        [
          #text(font: "Courier", size: footer_url_font_size, footer_url) 
          #h(1fr) 
          #text(size: footer_text_font_size, smallcaps(footer_text)) 
          #h(1fr) 
          #text(font: "Courier", size: footer_url_font_size, footer_email_ids)
        ]
      )
    ]
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Configure headings.
  set heading(numbering: "I.A.1.")
  show heading: it => locate(loc => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).at(loc)
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }

    set text(24pt, weight: 400)
    if it.level == 1 [
      // First-level headings are centered smallcaps.
      #set align(center)
      #set text({ 32pt })
      #show: smallcaps
      #v(50pt, weak: true)
      #if it.numbering != none {
        numbering("I.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(35.75pt, weak: true)
      #line(length: 100%)
    ] else if it.level == 2 [
      // Second-level headings are run-ins.
      #set text(style: "italic")
      #v(32pt, weak: true)
      #if it.numbering != none {
        numbering("i.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(10pt, weak: true)
    ] else [
      // Third level headings are run-ins too, but different.
      #if it.level == 3 {
        numbering("1)", deepest)
        [ ]
      }
      _#(it.body):_
    ]
  })

  // Arranging the logo, title, authors, and department in the header.
  align(center,
    grid(
      rows: 2,
      columns: (univ_logo_column_size, title_column_size),
      column-gutter: 0pt,
      row-gutter: 50pt,
      image(univ_logo, width: univ_logo_scale),
      text(title_font_size, title + "\n\n") + 
      text(authors_font_size, emph(authors) + 
          "   " + departments + " "),
    )
  )

  // Start three column mode and configure paragraph properties.
  show: columns.with(num_columns, gutter: 64pt)
  set par(justify: true, first-line-indent: 0em)
  show par: set block(spacing: 0.65em)

  // Display the keywords.
  if keywords != () [
      #set text(24pt, weight: 400)
      #show "Keywords": smallcaps
      *Keywords* --- #keywords.join(", ")
  ]

  // Display the poster's contents.
  body
}
// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: doc => poster(
   title: [Visualization PM2.5 Concentrations in the World (2017-2019)], 
  // TODO: use Quarto's normalized metadata.
   authors: [Ng Wei Herng, Timothy Zoe Delaya, Clarence Agcanas, Yeo Song Chen, Lee Ru Yuan], 
   departments: [~], 
   size: "36x24", 

  // Institution logo.
   univ_logo: "./images/sitlogo.png", 

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
   footer_text: [AAI1001 AY23/24 Tri 3 Team Project], 

  // Any URL, like a link to the conference website.
   footer_url: [~], 

  // Emails of the authors.
   footer_email_ids: [Team 06], 

  // Color of the footer.
   footer_color: "ebcfb2", 

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  

  // Number of columns in the poster.
  

  // University logo's scale (in %).
  

  // University logo's column size (in in).
  

  // Title and authors' column size (in in).
  

  // Poster title's font size (in pt).
  

  // Authors' font size (in pt).
  

  // Footer's URL and email font size (in pt).
  

  // Footer's text font size (in pt).
  

  doc,
)


= Original Data Visualization in News Media
<original-data-visualization-in-news-media>
The visualization titled "Comparing PM2.5 Concentrations in Capital Cities" created by Pallavi Rao (2023) and published on "The Visual Capitalist", presents a snapshot of PM2.5 air pollution levels in various capital cities around the world for the year 2022. PM2.5 refers to particulate matter that is less than 2.5 micrometers in diameter, which is small enough to penetrate the lungs and enter the bloodstream, posing significant health risks.

#figure([
#box(width: 20%,image("./images/CPArQuality.jpg"))
], caption: figure.caption(
position: bottom, 
[
Visualized: Air Quality and Pollution in 50 Capital Cities (IQAir 2022 World Air Quality Report)
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


This visualization uses a series of red circles to represent the PM2.5 concentrations in each capital city. The number of circles corresponds to the level of PM2.5 concentration that exceeds the World Health Organization’s (WHO) safe limit for PM2.5, which is 5 µg/m³. Any value above this indicates a higher risk for adverse health effects.

== Issues with the Original Visualization
<issues-with-the-original-visualization>
The original visualization clearly shows air pollution in popular cities but lacks additional factors like population size and GDP, which could explain the pollution levels. The use of multiple red circles makes it overwhelming and confusing, hindering quick comprehension of relative pollution levels between cities.

= Dataset
<dataset>
The data set we have chosen to use comes from the World Health Organization (WHO) which provides data on air quality for various countries from a wider year range. The data set contains information on PM2.5 concentrations for different countries and years and is also more precise as WHO has a 60% inclusion requirement whereby the recorded data require annual data availability of at least 60% of the total number of hours in a year to be included. Alongside this data set, we have also chosen to use 3 additional data set for the purposes of enhancing the visualization, as well as to improve on the data engineering and data cleaning aspect of the WHO data set.

+ Country Codes (2024)
+ Population Data (2024)
+ GDP Data (2024)

== Data cleaning and preparation
<data-cleaning-and-preparation>
We began by reading in the PM2.5 concentration dataset and filtered it to include data from 2017 to 2019. For GDP data, we skipped metadata, transformed it from wide to long format, renamed columns for clarity, and imputed missing values using previous years’ data. Unnecessary columns were dropped, and the data was filtered to include 2017-2019 before saving to a new CSV file. The population data was similarly cleaned and filtered for 2017-2019, with missing values imputed from previous years. We merged the GDP and population data with the PM2.5 dataset on matching country names and years, dropped any remaining rows with null values, and saved the final complete dataset to a new CSV file for further analysis.

= Improved Visualisation
<improved-visualisation>
#block(
fill:luma(230),
inset:8pt,
radius:4pt,
[
To improve upon the original visualization, decided that we would create three visualizations to provide a more comprehensive and insightful analysis of PM2.5 concentrations globally. These visualizations include:

- #strong[Improved Visual Appeal];: All of our visualizations are designed to be visually appealing and easy to understand, making it easier for the audience to interpret the data.
- #strong[Additional Data];: We incorporated population and GDP data to provide context and insights into the factors contributing to air pollution levels in different regions. This additional information enhances the audience’s understanding of the underlying causes of pollution.
- #strong[Interactive Elements];: All of our visualizations are interactive, allowing users to explore the data further by hovering over data points or selecting specific countries to view detailed information.

])

== Choropleth Map
<choropleth-map>
The choropleth map displays PM2.5 concentrations in countries globally, with darker colors representing higher PM2.5 levels. This visualization allows for quick and clear comparison of air quality across countries. Unfortunately, due to the lack of data of air pollution, most countries are greyed out. However, the countries with data are shown in the map below.

#figure([
#box(width: 95%,image("./images/choroplethmap.png"))
], caption: figure.caption(
position: bottom, 
[
Choropleth Map showing the Global PM2.5 Levels
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


== Scatter Plot, PM2.5 vs GDP
<scatter-plot-pm2.5-vs-gdp>
#figure([
#box(width: 85%,image("images/scatterplot.png"))
], caption: figure.caption(
position: bottom, 
[
Global PM2.5 vs GDP
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


- #strong[Averaging of Cities to Get Country Air Pollution]

To derive country-level air pollution data from city-level data, we aggregate the city-level PM2.5 concentrations by taking the average for each country. This process involves grouping the data by country and year, and then computing the mean PM2.5 concentration for each group. By doing this, we obtain a representative value of PM2.5 concentration for each country, which can then be used for further analysis.

- #strong[Analysis using Trend Line]

The trend line provides a visual representation of the general pattern or relationship between GDP and PM2.5 concentrations. This can help to identify whether higher GDP is associated with higher or lower levels of air pollution. We use LOESS Method because it does not assume a specific functional form (like linear regression) and can adapt to the underlying data structure, providing a more flexible and accurate representation of the relationship.

== Scatter Plot, PM2.5 vs Population
<scatter-plot-pm2.5-vs-population>
#figure([
#box(width: 75%,image("images/population.png"))
], caption: figure.caption(
position: bottom, 
[
Global PM2.5 vs Population
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


This scatter plot shows the relationship between PM2.5 values and population size for each city in the country, the bubbles are color coded by their region. The trend line provides a visual representation of the general pattern or relationship between population size and PM2.5 concentrations. This can help to identify whether higher population size is associated with higher or lower levels of air pollution.

= Further Suggestions for Improvement
<further-suggestions-for-improvement>
- #strong[Incorporate More Data];: Include additional datasets such as weather data, industrial activity, and traffic congestion to provide a more comprehensive analysis of air pollution.
- #strong[Enhance Interactivity];: Add more interactive elements such as filters, sliders, and dropdown menus to allow users to customize their viewing experience.
- #strong[Include wider Historical Data];: Incorporate historical data to analyze trends and patterns in air pollution levels over time.

= Conclusion
<conclusion>
Our improved visualizations provide a more comprehensive and insightful analysis of PM2.5 concentrations globally. By incorporating additional data on population and GDP, we have enhanced the audience’s understanding of the factors contributing to air pollution levels in different regions. The interactive elements allow users to explore the data further and gain deeper insights into the relationship between air pollution, population size, and GDP. Overall, our visualizations offer a more engaging and informative way to visualize air quality data and raise awareness of the importance of addressing air pollution on a global scale.
