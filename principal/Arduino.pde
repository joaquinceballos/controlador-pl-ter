/**
* Comunicación con el Arduino
*/
class TrazoPlotter {
  ArrayList<Punto> trazo;
  int ultimoPunto = 0;
  boolean pintable;

  boolean funciona;

  final int PUNTOS_SUBTRAZO = 10;

  TrazoPlotter(ArrayList<Punto> trazo, boolean pintable) {
    this.trazo = trazo;
    this.pintable = pintable;
  }

  /**
   * Si el arduino está listo y quedan pendientes puntos del trazo por pasar, hace un subtrazo y se envía
   *
   * Si el arduino está listo y se ha completato el trazo entero, retorna true, false en caso contrario
   */
  boolean nuevoSubtrazo() {
    if (!funciona) {
      print(" ");
    }
    String lectura = puerto.readStringUntil(';');
    if (lectura != null) {
    }
    if (lectura != null && lectura.equals("OK;")) {
      funciona = true;
      if (ultimoPunto >= trazo.size()) {
        return true;
      } else {
        StringBuilder sB = new StringBuilder();
        sB.append("L");
        int i;
        for (i = ultimoPunto; i < min(trazo.size(), ultimoPunto + PUNTOS_SUBTRAZO); i++) {
          sB.append(trazo.get(i).x + " ");
          sB.append(trazo.get(i).y + " ");
        }
        ultimoPunto = i;
        sB.append("; ");
        puerto.write(sB.toString());
      }
    }
    return false;
  }
}
