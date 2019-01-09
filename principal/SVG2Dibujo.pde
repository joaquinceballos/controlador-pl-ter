final int ANCHO_SVG = 3200;
final int ALTO_SVG = 800;

/**
 * Transforma un SVG generado por el módulo TSPArt en un dibujo del modelo
 * Se da por hecho que el SVG tiene las proporciones de un folio A4 y está
 * en orientación vertial
 *
 */
void svg2Dibujo(String ruta) {
  XML svg = loadXML(ruta);
  XML path = svg.getChildren("g")[0].getChildren("g")[0].getChild("path");
  ArrayList<Float> floats = new ArrayList<Float>();
  for (String punto : path.getString("d").split(" ")) {
    try {
      floats.add(Float.parseFloat(punto));
    }
    catch(NumberFormatException e) {
      // no es un float, seguramente salto de carro...
    }
  }
  ArrayList<PuntoRelativo> inicio = new ArrayList<PuntoRelativo>();
  ArrayList<PuntoRelativo> puntosCurva = new ArrayList<PuntoRelativo>();
  ArrayList<PuntoRelativo> fin = new ArrayList<PuntoRelativo>();
  for (int i = 0; i < floats.size(); i += 2) {
    float x = map(floats.get(i), ANCHO_SVG / 2 - (ALTO_SVG / sqrt(2)) / 2, ANCHO_SVG / 2 + (ALTO_SVG / sqrt(2)) / 2, 0, 1);
    float y = map(floats.get(i + 1), 0, ALTO_SVG, 0, 1);
    puntosCurva.add(new PuntoRelativo(x, y));
  }
  inicio.add(new PuntoRelativo(0, 0));
  inicio.add(puntosCurva.get(0));
  fin.add(puntosCurva.get(puntosCurva.size() - 1));
  fin.add(new PuntoRelativo(0, 0));
  ArrayList<Curva> curvas = new ArrayList<Curva>();
  curvas.add(new Curva(-1, inicio, true, false));
  curvas.add(new Curva(-1, puntosCurva, true));
  curvas.add(new Curva(-1, fin, true, false));
  dibujos.add(new Dibujo(curvas, true, "prueba", -1, grosorTrazoTSPArt));
  nuevoDibujo = true;
}
