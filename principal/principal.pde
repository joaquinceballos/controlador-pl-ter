import processing.serial.*; //<>//

import javax.xml.bind.DatatypeConverter;
import java.io.ByteArrayInputStream;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import java.util.NoSuchElementException;


// url del servicio rest
final String URL = "http://plotter.ddns.net:8080";

// frecuancia de consulta por nuevos dibujos
final int FRECUENCIA_CONSULTA = 5000;

// control para el hilo que carga dibujos, sólo uno a la vez
boolean hiloTrabajando = false;

// control para el hilo que genera el path del TSPArt, sólo uno a la vez
boolean hiloTSPArtTrabajando;

// dibujos
ArrayList<Dibujo> dibujos = new ArrayList<Dibujo>();

// provisional para ver algo de momento
int indicePintado = -1;

// colores
final color BLANCO = #FFFFFF;
final color NEGRO = #000000;
final color COLOR_FONDO = #333333;
final color ROJO = #FF0000;
final color AZUL = #0000FF;
final color GRIS = color(128);
final color COLOR_BARRA = #B7BDC1;
final color COLOR_TRAZO = COLOR_FONDO;

// hay nuevos dibujos recién cargados
boolean nuevoDibujo;

// plóter simulado
final int MARGEN_PLOTTER = 50;
final int ANCHO_BARRA_PLOTTER = 10;
final int ANCHO_DIVISOR_PANTALLA = 10;
final byte MIN_PAUSA = 0;
final byte MAX_PAUSA = 10;
byte pausaPintandoSimulador =  9;
int x0PlotterSimulado, y0PlotterSimulado, anchoPlotterSimulado, altoPlotterSimulado;

// dibujo está siendo pintado en estos momentos
boolean dibujoCompleto;

// control del tiempo del simulador del plóter
long tInicioSimulacion;

// medidas del plóter real (en pasos) 
// 1000 pasos de margen por cada lado, las medidas del largo en pasos del A4 que tomamos es 15290 (se puede afinar más adelante si hiciese falta)
final int MARGEN_PASOS = 0;
final int X0_PLOTTER = MARGEN_PASOS;
final int Y0_PLOTTER = MARGEN_PASOS; 
final int ANCHO_PLOTTER = 10812 / 2 - 2 * MARGEN_PASOS; // división por 2 provisional
final int ALTO_PLOTTER = 15290 / 2 - 2 * MARGEN_PASOS;

byte grosorTrazoTSPArt;
byte grosorTrazoDibujo;

// comunicación con el arduino
Serial puerto;
// dibujo que pinta el plóter real (esto es provisional)
Dibujo dibujoPintandoEnPlotter;
// control para saber si el plóter real está trabajando
boolean plotterRealTrabajando;

void setup() {
  fullScreen();
  background(COLOR_FONDO);
  stroke(NEGRO);
  thread("cargaNuevosDibujos");
  thread("cargaNuevasImagenes");
  thread("controlTextoSimulacion");
  // división de la pantalla
  strokeWeight(2);
  rect(width - width / 3, MARGEN_PLOTTER, ANCHO_DIVISOR_PANTALLA, height - 2 * MARGEN_PLOTTER);

  grosorTrazoTSPArt = (byte) (height / 500);
  grosorTrazoDibujo = (byte) (height / 250);

  println(grosorTrazoTSPArt);

  // medidas del plotter simulado en pantalla
  x0PlotterSimulado = width -  width / 3 + MARGEN_PLOTTER;
  anchoPlotterSimulado = width / 3 - 2 * MARGEN_PLOTTER;
  altoPlotterSimulado = (int) (sqrt(2) * anchoPlotterSimulado);
  y0PlotterSimulado = height / 2 - altoPlotterSimulado / 2;

  // divisor vertical zona simulador plóter  
  stroke(NEGRO);
  fill(BLANCO);
  rect(width - width / 3, MARGEN_PLOTTER, 10, height - 2 * MARGEN_PLOTTER);

  textFont(createFont("Century Gothic", 1));
  pintaFolioPlotter();
  pintarTextoCentro();
  pintaImagenBeta();

  dibujoCompleto = true;

  // Se pueden cargar todos los svg guardados
  for (String svg : new File(sketchPath() + "/data/TSPArt/").list()) {
    //svg2Dibujo("/data/TSPArt/" + svg);
  }  
  for (String dibujo : new File(sketchPath() + "/data/Dibujos/").list()){     
      dibujos.add(parseaDibujo(loadJSONObject("/data/Dibujos/" + dibujo))); 
  }
  nuevoDibujo = !dibujos.isEmpty();
  
  // comunicación con arduino, si no se usa dejarlo a null
  //puerto = new Serial(this, "COM3", 9600);
}

void draw() {
  if (nuevoDibujo && dibujoCompleto) {
    nuevoDibujo = false;
    dibujoCompleto = false;
    indicePintado = dibujos.size() - 1;
    thread("recorreCurvasMarcandoPuntosVisibles");
    tInicioSimulacion = millis();
  }
  if (indicePintado != -1 && !dibujoCompleto) {
    simularPlotter();
  }
  if (!dibujos.isEmpty() && indicePintado >= 0 && dibujos.get(indicePintado) != null && !plotterRealTrabajando) {
    dibujoPintandoEnPlotter = dibujos.get(indicePintado);
    if (puerto != null) {
      thread("plotterReal");
    }
  }  
  fill(COLOR_FONDO);
  noStroke();
  rect(x0PlotterSimulado - MARGEN_PLOTTER + ANCHO_DIVISOR_PANTALLA + 5, 
    height - y0PlotterSimulado + MARGEN_PLOTTER / 2, 
    anchoPlotterSimulado + 2 * MARGEN_PLOTTER - ANCHO_DIVISOR_PANTALLA - 5, 
    height);
  pintaTextoVelocidad();
}

void plotterReal() {
  long inicio = millis();
  long tUltimoPrint = 0;
  plotterRealTrabajando = true;
  long totalPuntos = 0;
  long puntos = 0;
  for (Curva curva : dibujoPintandoEnPlotter.curvas) {
    totalPuntos += curva.pasos.size();
  }
  for (Curva curva : dibujoPintandoEnPlotter.curvas) {
    TrazoPlotter trazoPlotter = new TrazoPlotter(curva.pasos, curva.pintable);
    while (!trazoPlotter.nuevoSubtrazo()) {
      // cada minuto imprime el porcentaje completado
      if (millis() - tUltimoPrint > 60000) {
        tUltimoPrint = millis();
        println("completado " + ((puntos + trazoPlotter.ultimoPunto) * 100 / totalPuntos) + "%");
      }
    }
    tUltimoPrint = millis();
    puntos += curva.pasos.size();
    println("completado " + (puntos * 100 / totalPuntos) + "%");
  }
  long t2 = millis() - inicio;
  println("tiempo empleado: " + (t2 / 60000) + " minutos y " + (t2 % 60000 / 1000) + " segundos");
  //plotterRealTrabajando = false;
}

void keyPressed() {
  if (keyCode == UP) {
    pausaPintandoSimulador = (byte) max(MIN_PAUSA, pausaPintandoSimulador - 1);
  } else if (keyCode == DOWN) {
    pausaPintandoSimulador = (byte) min(MAX_PAUSA, pausaPintandoSimulador + 1);
  }
  if (dibujos.size() > 0 && (keyCode == RIGHT || keyCode == LEFT)) {
    if (keyCode == LEFT) {
      indicePintado = indicePintado == 0 ? dibujos.size() - 1 : indicePintado - 1;
    } else {      
      indicePintado = indicePintado == dibujos.size() - 1 ? 0 : indicePintado + 1;
    }
    marcarInvisible(dibujos.get(indicePintado));
    thread("recorreCurvasMarcandoPuntosVisibles");
    dibujoCompleto = false;
  }
}

/**
 Recorre el dibujo pasado marcando todos sus puntos como invisibles.
 */
void marcarInvisible(Dibujo dibujo) { 
  for (Curva curva : dibujo.curvas) {
    for (Punto punto : curva.pixeles) {
      punto.visible = false;
    }
  }
}

/**
 Este método se debe ejecutar siempre desde un hilo distinto al principal.
 
 Recorre el dibujo que está siendo pintado en el plóter simulado, marcando 
 cada punto del mismo como visible. Tras marcar cada punto hará una pausa. 
 Si el dibujo que está siendo pintado ha cambiado, se termina automáticamente
 */
void recorreCurvasMarcandoPuntosVisibles() {
  int marcando = indicePintado;
  if (marcando != -1) {
    for (Curva curva : dibujos.get(marcando).curvas) {
      for (Punto punto : curva.pixeles) {
        if (indicePintado != marcando) {
          return;
        }
        punto.visible = true;
        delay(pausaPintandoSimulador);
      }
    }
  }
}

/**
 * Crea un nuevo objeto TSPArt pasando la imagen y nombre del fichero .svg a generar
 * Operación muy pesada depndiendo del número de generaciones y número de puntos.
 * Se podrían pasar el número de puntos al constructor... escogiendo el usuario lo que prefiera en el html... por ejmplo, es una opción, si no dejar unos 2000 - 5000 y va bien
 *
 * Algunas veces puede saltar excepción NoSuchElementException, en esos casos se intenta de nuevo haciendo una llamada recursiva
 */
void tspArt(PImage imagen) {
  try {
    String fichero = nombreSVG();
    TSPArt t  = new TSPArt(imagen, fichero);
    t.process();
    svg2Dibujo(fichero);
  } 
  catch(NoSuchElementException e) {
    tspArt(imagen);
  }
}

/**
 * TODO Aún está en pruebas pero va tirando ok
 * Comprueba si hay imágenes nuevas consultando las ids de imágenes del resvicio REST
 * En caso que que sí:
 *   - Se descarga la primera de ellas y laborra del servidor
 *   - Llama a tspArt pasando la imagen para generar el SVG 
 */
void cargaNuevasImagenes() {
  while (true) {
    JSONArray jsonArray = loadJSONArray(URL + "/imagen/ids");
    if (jsonArray.size() > 0) {
      PImage imagen = loadImage(URL + "/imagen/descargar?id="+jsonArray.getLong(0), "png");
      loadStrings(URL + "/imagen/borrar?id=" + jsonArray.getLong(0));
      tspArt(imagen);
    }
    delay(FRECUENCIA_CONSULTA);
  }
}

void cargaNuevosDibujos() {
  while (true) {
    JSONArray jsonArray = loadJSONArray(URL + "/dibujo/descargar");
    for (int i = 0; i < jsonArray.size(); i++) {   
      JSONObject dibujo = jsonArray.getJSONObject(i);
      long id = dibujo.isNull("id") ? -1 : dibujo.getInt("id");
      loadStrings(URL + "/dibujo/borrar?id=" + id);
      saveJSONObject(dibujo, nombreDibujo());
      dibujos.add(parseaDibujo(dibujo));
    }
    nuevoDibujo = nuevoDibujo || jsonArray.size() > 0;
    delay(FRECUENCIA_CONSULTA);
  }
}

/**
 Simula trazar el dibujo cuyo índice es indicePintado, recorriendo todos sus
 puntos y pintándolos individualmente. Cuando se encuentra con un punto
 con la propiedad visible a false, pinta las barras del plóter y retorna.
 
 Si consigue recorrer el dibujo por completo, es decir, si todos sus puntos están marcados como 
 visibles, marca dibujoCompleto a true, de este modo no se debería de llamar de nuevo a este método 
 hasta que haya cambiado dibujo a pintar 
 */
void simularPlotter() {
  //println("dibujando:\t" + dibujo.id);
  Dibujo dibujo = dibujos.get(indicePintado);
  borraTercioPlotter();
  pintaFolioPlotter();
  strokeWeight(dibujo.gruesoTrazo); // TODO poner el grueso del trazo en plan dibujo.gruesoTrazo ahora que hay TSPArt, éstas se ven mejor con trazo fino
  stroke(COLOR_TRAZO);
  for (Curva curva : dibujo.curvas) {
    for (int i = 0; i < curva.pixeles.size(); i++) {   
      Punto punto = curva.pixeles.get(i);
      if (punto.visible && curva.pintable) {
        point(punto.x, punto.y);
      } else if (!punto.visible) {
        pintarBarrasPlotter(punto.x, punto.y, curva.pintable);
        pintaTextoSimulacion();
        return;
      }
    }
  }
  dibujoCompleto = true;
  pintarBarrasPlotter(x0PlotterSimulado, y0PlotterSimulado, false);
}

void borraTercioPlotter() {
  int pelin = 5;
  fill(COLOR_FONDO);
  noStroke();
  rect(x0PlotterSimulado - MARGEN_PLOTTER + ANCHO_DIVISOR_PANTALLA + pelin, 
    0, 
    anchoPlotterSimulado + 2 * MARGEN_PLOTTER - ANCHO_DIVISOR_PANTALLA - pelin, 
    height);
}

void pintaFolioPlotter() {
  fill(BLANCO);
  strokeWeight(2);
  stroke(NEGRO);
  rect(x0PlotterSimulado, y0PlotterSimulado, anchoPlotterSimulado, altoPlotterSimulado);
}

void pintarBarrasPlotter(int x, int y, boolean lapiz) {
  if (!dibujoCompleto) {
    int sobresale = 10;
    stroke(NEGRO);
    strokeWeight(2);        
    fill(COLOR_BARRA);
    rect(x - ANCHO_BARRA_PLOTTER / 2, 
      y0PlotterSimulado - sobresale, 
      ANCHO_BARRA_PLOTTER, 
      altoPlotterSimulado + 2 * sobresale);
    rect(x0PlotterSimulado - sobresale, 
      y - ANCHO_BARRA_PLOTTER / 2, 
      anchoPlotterSimulado + 2 * sobresale, 
      ANCHO_BARRA_PLOTTER);
    if (lapiz) {
      fill(ROJO);
      ellipse(x, y, 2 * ANCHO_BARRA_PLOTTER, 2 * ANCHO_BARRA_PLOTTER);
    }
  }
}
