// url del servicio rest donde se descargan los dibujos
final String url = "http://plotter.ddns.net:82";

// frecuancia de consulta por nuevos dibujos
final long FRECUENCIA_CONSULTA = 5000;

// tiempo de la última carga de dibujos
long tUltimaCarga;

// guarda la id del último dibujo descargado
long ultimaId = -1;

// control para el hilo que carga dibujos, sólo uno a la vez
boolean hiloTrabajando = false;

// dibujos
JSONArray dibujos = new JSONArray();

// provisional para ver algo de momento
int indicePintado = 0;

// colores
color blanco = #FFFFFF;
color negro = #000000;
color colorFondo = #F7F4D9;

void setup() {
  size(500, 707);
  background(colorFondo);
  stroke(negro);
  strokeWeight(5);
  thread("cargaNuevosDibujos");
}

void draw() {
  if (millis() - tUltimaCarga > FRECUENCIA_CONSULTA && !hiloTrabajando) {
    thread("cargaNuevosDibujos");
  }
}

/**
 provisional
 */
void keyPressed() {
  if (dibujos.size() > 0) {
    background(colorFondo);
    dibujar(indicePintado);
    indicePintado = indicePintado == dibujos.size() - 1 ? 0 : indicePintado + 1;
  }
}

/**
 provisional para ir viendo. dibuja a pantalla completa considerando que las proporciones son las de un folio
 */
void dibujar(int i) {
  JSONObject dibujo = dibujos.getJSONObject(i);
  if (dibujo == null) {
    println("dibujar() -> el dibujo es null y no debería");
    return;
  }
  boolean vertical = dibujo.getBoolean("vertical");
  JSONArray curvas = dibujo.getJSONArray("curvas");
  for (int j = 0; j < curvas.size(); j++) {
    JSONArray puntos = curvas.getJSONObject(j).getJSONArray("puntos");
    if (puntos.size() == 1) {
      pintaLinea(puntos.getJSONObject(0), puntos.getJSONObject(0), vertical);
    }
    for (int k = 1; k < puntos.size(); k++) {
      pintaLinea(puntos.getJSONObject(k - 1), puntos.getJSONObject(k), vertical);
    }
  }
}

void pintaLinea(JSONObject p0, JSONObject p1, boolean vertical) {
  float x0, y0, x1, y1;
  if (vertical) {
    x0 = p0.getFloat("x") * width;
    y0 = p0.getFloat("y") * height;
    x1 = p1.getFloat("x") * width;
    y1 = p1.getFloat("y") * height;
  } else {
    // se invierten
    x0 = width - p0.getFloat("y") * width;
    y0 = p0.getFloat("x") * height;
    x1 = width - p1.getFloat("y") * width;
    y1 = p1.getFloat("x") * height;
  }
  line(x0, y0, x1, y1);
}

void cargaNuevosDibujos() {
  hiloTrabajando = true;
  JSONArray jsonArray = loadJSONArray(url + "/dibujo/descargar" + (ultimaId == -1 ? "" : "?last=" + (ultimaId)));
  for (int i = 0; i < jsonArray.size(); i++) {    
    JSONObject dibujo = jsonArray.getJSONObject(i);
    ultimaId = dibujo.getInt("id");
    dibujos.setJSONObject(dibujos.size(), dibujo);
  }
  tUltimaCarga = millis();
  hiloTrabajando = false;
}
