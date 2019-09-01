# Module UI

#' @title   Module for visualizing spatial data
#' @description  This model is to visualize space related data such as latitude/longitude.
#'
#' @param id shiny id
#' @param input internal
#' @param output internal
#' @param session internal
#'
#' @rdname mod_spatial
#'
#' @keywords internal
#' @export
#' @importFrom shiny NS tagList
mod_spatial_ui <- function(id) {
  ns <- NS(id)
  fluidPage(
    fluidRow(
      column(
        class = "noPadding",
        12,
        fluidRow(
          column(
            6,
            selectInput(
              ns("mapTexture"),
              "Map Texture",
              choices = list(
                "OpenStreetMap.Mapnik" = "OpenStreetMap.Mapnik",
                "OpenStreetMap.BlackAndWhite" = "OpenStreetMap.BlackAndWhite",
                "Stamen.Toner" = "Stamen.Toner",
                "CartoDB.Positron" = "CartoDB.Positron",
                "Esri.NatGeoWorldMap" = "Esri.NatGeoWorldMap",
                "Stamen.Watercolor" = "Stamen.Watercolor",
                "Stamen.Terrain" = "Stamen.Terrain",
                "Esri.WorldImagery" = "Esri.WorldImagery",
                "Esri.WorldTerrain" = "Esri.WorldTerrain"
              ),
              selected = "Stamen.Toner"
            )
          ),
          column(
            6,
            selectInput(
              ns("mapColor"),
              "Points Color",
              choices = list(
                "Red" = 'red',
                "Green" = "green",
                "Blue" = "blue",
                "Black" = "black"
              )
            )
          )
        ),
        fluidRow(
          leafletOutput(
            ns("mymap"),
            height = "240px"
          )
        ),
        fluidRow(
          br(),
          selectizeInput(
            ns("show_vars"),
            "Columns to show:",
            choices = c(
              "scientificName",
              "countryCode",
              "locality",
              "decimalLatitude",
              "decimalLongitude",
              "coordinateUncertaintyInMeters",
              "coordinatePrecision",
              "elevation",
              "elevationAccuracy",
              "depth",
              "depthAccuracy",
              "establishmentMeans"
            ),
            multiple = TRUE,
            selected = c(
              "scientificName",
              "kingdom", 
              "phylum"
            )
          )
        ),
        fluidRow(
          DT::dataTableOutput(
            ns("table")
          )
        )
      )
    )
  )
}

# Module Server

#' @rdname mod_spatial
#' @export
#' @keywords internal
mod_spatial_server <- function(input, output, session, data) {
  ns <- session$ns
  
  output$mymap <- renderLeaflet({
    leaflet(
      data = na.omit(
        data()[c("decimalLatitude", "decimalLongitude")]
      )
    ) %>%
      addProviderTiles(
        input$mapTexture
        ) %>%
      addCircles(
        ~ decimalLongitude,
       ~ decimalLatitude,
       color = input$mapColor
     ) %>%
     leaflet.extras::addDrawToolbar(
       targetGroup='draw',
       polylineOptions = FALSE,
       circleOptions = FALSE,
       markerOptions = FALSE,
       rectangleOptions = FALSE,
       circleMarkerOptions = FALSE,
       editOptions = leaflet.extras::editToolbarOptions()
     ) %>%
     addLayersControl(
       overlayGroups = c('draw'),
       options = layersControlOptions(
         collapsed=FALSE
       )
     ) 
  })
      
  output$table <- DT::renderDataTable({
   data()[input$show_vars]
  })
      
  observeEvent(
    input$mymap_draw_new_feature,
    {
      output$table <- DT::renderDataTable({
        data <- na.omit(
          data()[c(
            "decimalLatitude",
            "decimalLongitude"
          )]
        )
      cities_coordinates <- SpatialPointsDataFrame(
        data[,c(
          "decimalLongitude",
          "decimalLatitude"
        )],
        data
      )
      
      #get the coordinates of the polygon
      polygon_coordinates <- 
        input$mymap_draw_new_feature$geometry$coordinates[[1]]
      
      #transform them to an sp Polygon
      drawn_polygon <- 
        Polygon(
          do.call(
            rbind,
            lapply(
              polygon_coordinates,
              function(x){c(x[[1]][1],x[[2]][1])}
            )
          )
        )

      #use over from the sp package to identify selected cities
      selected_cities <- 
        cities_coordinates %over% 
        SpatialPolygons(
          list(
            Polygons(
              list(
                drawn_polygon
              ),
              "drawn_polygon"
            )
          )
        )
      
        #print the name of the cities
        geo <- as.data.frame(
          data()[which(
            !is.na(
              selected_cities
            )
          ),
          colnames(
            data()
          )]
        )
        
        geo[input$show_vars]
      })
    }
  )
      
  observeEvent(
    input$mymap_draw_deleted_features,
    {
      output$table <- DT::renderDataTable({
        data()[input$show_vars]
      })
    }
  )
  
}