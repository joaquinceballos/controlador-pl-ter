class Dibujo {

  final long id;
  final String autor;
  ArrayList<Curva> curvas;
  final boolean vertical;
  final byte gruesoTrazo;

  Dibujo(ArrayList<Curva> curvas, boolean vertical, String autor, long id, byte gruesoTrazo) {
    this.curvas = curvas;
    this.vertical = vertical;
    this.autor = autor;
    this.id = id;
    this.gruesoTrazo = gruesoTrazo;
  }
}

class Curva {

  // la verdad que la id sobra...
  final long id;

  boolean pintable = true;

  // para pintar el dibujo en pantalla
  ArrayList<Punto> pixeles = new ArrayList<Punto>();

  // para pintar el dibujo en papel
  ArrayList<Punto> pasos = new ArrayList<Punto>();

  Curva (long id, ArrayList<PuntoRelativo> puntosRelativos, boolean vertical, boolean pintable) {
    this(id, puntosRelativos, vertical);
    this.pintable = pintable;
  }

  Curva(long id, ArrayList<PuntoRelativo> puntosRelativos, boolean vertical) {
    this.id = id;
    this.pixeles = rutaDibujo(puntosRelativos, x0PlotterSimulado, y0PlotterSimulado, anchoPlotterSimulado, altoPlotterSimulado, vertical);
    this.pasos = rutaDibujo(puntosRelativos, X0_PLOTTER, Y0_PLOTTER, ANCHO_PLOTTER, ALTO_PLOTTER, vertical);
  }
}

class Punto {
  final int x, y;
  boolean visible;

  Punto(int x, int y) {
    this.x = x;
    this.y = y;
  }

  public boolean equals(Punto otroPunto) {
    return this.x == otroPunto.x && this.y == otroPunto.y;
  }
}

class PuntoRelativo {
  final float x, y;

  PuntoRelativo(float x, float y) {
    this.x = x;
    this.y = y;
  }
}
