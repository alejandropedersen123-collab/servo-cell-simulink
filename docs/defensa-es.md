# Cómo defender la estación servo

## Explicación de un minuto

«He preparado una puesta en marcha virtual de una estación de transferencia. La secuencia verifica que hay una pieza, mueve un eje a la estación, espera su confirmación y vuelve al origen. El control combina posición y velocidad, limita aceleración y fuerza, y evita acumulación del integrador. Las pruebas inyectan fallos y verifican que no se cuenten ciclos falsos ni se rearranque después de una emergencia».

## Demo de cinco minutos

1. Abre el modelo y sigue el flujo: órdenes, secuencia, servo, planta y realimentación.
2. Ejecuta `simulate_scenario('nominal')` y muestra cuándo cambia cada estado.
3. Ejecuta `simulate_scenario('emergency_stop')`: enseña el enclavamiento, el reset rechazado con la máquina habilitada y el reset aceptado estando deshabilitada.
4. Enseña `run_acceptance`, sus requisitos y los CSV con resultados medidos.
5. Explica qué componentes reales faltan: PLC, variador, encoder, red industrial y circuito de seguridad independiente.

## Preguntas importantes

- ¿Por qué dos lazos? El de posición genera la consigna de velocidad; el de velocidad produce fuerza.
- ¿Qué es windup? Acumulación del integrador cuando el actuador no puede producir la orden calculada. La realimentación de saturación reduce esa acumulación.
- ¿Por qué comprobar velocidad al llegar? Para no confundir un cruce rápido del punto con una llegada estable.
- ¿Reset equivale a start? No. El reset elimina una causa recuperada; volver a moverse requiere otra acción y posición de referencia válida.
- ¿Se puede conectar a una máquina tal cual? No: la planta es idealizada y no existe validación de hardware ni seguridad certificada.
- ¿Qué pasa tras una emergencia lejos del origen? Se bloquea un nuevo ciclo automático; falta implementar un procedimiento de recuperación/homing validado.

## Ejercicios para comprenderlo

Duplica la masa y compara los resultados; cambia la fricción; introduce una demora de 50 ms en el mando; añade una prueba de inicio lejos de origen. Antes de presentar cambios como tuyos, ejecútalos, explica sus consecuencias y documenta lo aprendido. La creación inicial fue asistida por IA; el valor en entrevista está en tu comprensión y tus decisiones verificables.
