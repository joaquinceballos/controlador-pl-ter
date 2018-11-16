class Dibujo {

  final long id;
  final String autor;
  ArrayList<Curva> curvas;
  final boolean vertical;

  Dibujo(ArrayList<Curva> curvas, boolean vertical, String autor, long id) {
    this.curvas = curvas;
    this.vertical = vertical;
    this.autor = autor;
    this.id = id;
  }
}

class Curva {

  // la verdad que la id sobra...
  final long id;

  boolean pintable = true;

  // para pintar el dibujo en pantalla
  ArrayList<Punto> puntosPixeles = new ArrayList<Punto>();

  // para pintar el dibujo en papel
  ArrayList<Punto> puntosPasos = new ArrayList<Punto>();

  Curva (long id, ArrayList<PuntoPorcentaje> puntosPorcentajes, boolean vertical, boolean pintable) {
    this(id, puntosPorcentajes, vertical);
    this.pintable = pintable;
  }

  Curva(long id, ArrayList<PuntoPorcentaje> puntosPorcentajes, boolean vertical) {
    this.id = id;
    this.puntosPixeles = rutaDibujo(puntosPorcentajes, x0PlotterSimulado, y0PlotterSimulado, anchoPlotterSimulado, altoPlotterSimulado, vertical);
    //this.puntosPasos = rutaDibujo(puntosPorcentajes, X0_PLOTTER_REAL, Y0_PLOTTER_REAL, ANCHO_PLOTTER_REAL, ALTO_PLOTTER_REAL, vertical);
  }
}

class Punto {
  final int x, y;
  boolean visible;

  Punto(int x, int y) {
    this.x = x;
    this.y = y;
  }
}

class PuntoPorcentaje {
  float x, y;

  PuntoPorcentaje(float x, float y) {
    this.x = x;
    this.y = y;
  }
}
