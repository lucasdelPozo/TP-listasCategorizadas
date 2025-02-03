.data
# Variables y estructuras de datos
slist: .word 0
cclist: .word 0
wclist: .word 0
categorycount: .word 0
categorystorage: .space 1000
objectcount: .word 0
objectstorage: .space 1500
.align 2
schedv: .space 32
buffer: .space 50
# Mensajes
menu: .ascii "Colecciones de objetos categorizados\n"
      .ascii "====================================\n"
      .ascii "1-Nueva categoria\n"
      .ascii "2-Siguiente categoria\n"
      .ascii "3-Categoria anterior\n"
      .ascii "4-Listar categorias\n"
      .ascii "5-Borrar categoria actual\n"
      .ascii "6-Anexar objeto a la categoria actual\n"
      .ascii "7-Listar objetos de la categoria\n"
      .ascii "8-Borrar objeto de la categoria\n"
      .asciiz "0-Salir\n"
enteroption: .asciiz "Ingrese la opcion deseada: "
selectcategory: .asciiz ">"
error: .asciiz "Error: "
errorobject: .asciiz "No se encontro el objeto"
optioninvalid: .asciiz "Opcion invalida.\n"
return: .asciiz "\n"
catName: .asciiz "Ingrese el nombre de una categoria: "
selCat: .asciiz "Se ha seleccionado la categoria: "
idObj: .asciiz "Ingrese el ID del objeto a eliminar: "
objName: .asciiz "Ingrese el nombre de un objeto: "
success: .asciiz "La operación se realizó con éxito.\n\n"

.text
.globl main

# Programa principal
main:
    # Inicializar variables
    la $t0, slist
    li $t1, 0
    sw $t1, 0($t0)
    la $t0, cclist
    li $t1, 0
    sw $t1, 0($t0)
    la $t0, wclist
    li $t1, 0
    sw $t1, 0($t0)

    # Inicializar vector de funciones
    la $t0, schedv
    la $t1, newcategory
    sw $t1, 0($t0)
    la $t1, nextcategory
    sw $t1, 4($t0)
    la $t1, prevcategory
    sw $t1, 8($t0)
    la $t1, listcategory
    sw $t1, 12($t0)
    la $t1, delcategory
    sw $t1, 16($t0)
    la $t1, addobject
    sw $t1, 20($t0)
    la $t1, listobject
    sw $t1, 24($t0)
    la $t1, delobject
    sw $t1, 28($t0)

    # Mostrar menú inicial
    li $v0, 4
    la $a0, menu
    syscall

loop:
    # Mostrar retorno y leer opción
    li $v0, 4
    la $a0, enteroption
    syscall
    li $v0, 5
    syscall
    move $t2, $v0  # Guardar opción ingresada

    # Validar opción
    beqz $t2, exitmenu  # Salir si la opción es 0
    bltz $t2, invalid_option
    li $t3, 9
    bge $t2, $t3, invalid_option 
    sub $t2, $t2, 1	# Ajustamos la opcion ingresada 
    # Ejecutar función correspondiente
    li $t3, 4
    mul $t4, $t2, $t3
    la $t0, schedv
    add $t0, $t0, $t4
    lw $t1, 0($t0)
    jalr $t1
    j loop

invalid_option:
    li $v0, 4
    la $a0, error
    syscall
    
    li $v0, 4
    la $a0, optioninvalid
    syscall
    
    j loop
exitmenu:
    li $v0, 10
    syscall
smalloc:
    lw $t0, slist          # Cargar la lista libre
    beqz $t0, sbrk    # Si está vacía, llamar a sbrk
    move $v0, $t0          # Retornar dirección del nodo disponible
    lw $t0, 12($t0)        # Actualizar slist al siguiente nodo libre
    sw $t0, slist
    jr $ra                 # Retornar  
# Implementación de sbrk
sbrk:
    li $a0, 16             # Tamaño del nodo (4 palabras)
    li $v0, 9              # Syscall para asignar memoria
    syscall
    jr $ra     
# Crear nueva categoría
newcategory:
    addiu $sp, $sp, -8    # Reservar espacio en el stack
    sw $ra, 0($sp)        # Guardar el valor de retorno

    # Asignar nodo con smalloc
    jal smalloc
    move $t6, $v0         # Dirección del nuevo nodo

    # Solicitar el nombre de la categoría
    li $v0, 4
    la $a0, catName
    syscall
    li $v0, 8
    la $a0, buffer
    li $a1, 49
    syscall

    # Asignar memoria para el nombre de la categoría
    li $a0, 50
    li $v0, 9
    syscall
    move $t7, $v0         # Dirección del nombre

    # Copiar el nombre desde el buffer
    la $t8, buffer
    move $t9, $t7

copyname:
    lb $t0, 0($t8)
    sb $t0, 0($t9)
    beqz $t0, endcopy
    addiu $t8, $t8, 1
    addiu $t9, $t9, 1
    j copyname

endcopy:                                            
    # Guardar el nombre en el nodo
    sw $zero, 4($t6)      # Guardar la direccion de la lista de objetos (0 por defecto)
    sw $t7, 8($t6)        # Guardar la dirección del nombre en el nodo

    # Configurar la lista circular
    lw $t8, cclist        # Cargar la lista actual
    beqz $t8, emptylist   # Si la lista está vacía, inicializarla

    # Conectar el nuevo nodo en la lista
    lw $t9, 0($t8)        # $t9 = último nodo ("prev" del primero)
    sw $t9, 0($t6)        # "prev" del nuevo nodo apunta al último nodo
    sw $t6, 12($t9)       # "next" del último nodo apunta al nuevo nodo
    sw $t8, 12($t6)       # "next" del nuevo nodo apunta al primero
    sw $t6, 0($t8)        # "prev" del primero apunta al nuevo nodo
    j setcurrent

emptylist:
    # Si la lista está vacía, el nuevo nodo apunta a sí mismo
    sw $t6, cclist        # Actualizar cclist con el nuevo nodo
    sw $t6, 0($t6)        # "prev" apunta a sí mismo
    sw $t6, 12($t6)       # "next" apunta a sí mismo
    sw $t6, wclist
setcurrent:
    # Incrementar el contador de nodos
    lw $t1, categorycount    # Cargar node_count
    addi $t1, $t1, 1      # Incrementar en 1
    sw $t1, categorycount    # Guardar el nuevo valor

    # Mensaje de éxito
    la $a0, success
    li $v0, 4
    syscall

    lw $ra, 0($sp)        # Restaurar $ra
    lw $a0, 4($sp)        # Restaurar $a0
    addiu $sp, $sp, 8     # Restaurar el stack
    jr $ra                # Retornar

errorspacefull:
    # Mostrar mensaje de error por falta de espacio
    li $v0, 4
    la $a0, error
    syscall

    li $v0, 1
    li $a0, 302           # Código de error 302 (sin espacio)
    syscall

    li $v0, 4
    la $a0, return
    syscall

    lw $ra, 0($sp)        # Restaurar $ra
    addiu $sp, $sp, 8     # Restaurar el stack
    jr $ra                # Retornar
listcategory:
    addiu $sp, $sp -8
    sw $ra, 0($sp)
    
    lw $t0, cclist       # Tomamos la direccion de la lista de categorias
    beqz $t0, error301   # Si es 0, dara error
    lw $t3, wclist       # Tomamos la direccion de la lista en curso
    
    move $t1, $t0        # $t1 = puntero que servira para recorrer la lista
    move $t5, $t0        # $t5 = puntero que servira para terminar el listado
        
listloop:
    beq $t1, $t3, printselectcategory	 
    li $v0, 4	
    lw $a0, 8($t1)
    syscall  # imprime la categoria seleccionada
    
    li $v0, 4
    la $a0, return
    syscall
travelloop:        
    lw $t1, 12($t1)  # actualiza a la siguiente lista
    bne $t1, $t5, listloop # si la siguiente categoria es igual a la primera que se imprimio, termina el recorrido
    j endlist
printselectcategory:
    # Imprime la categoria que esta en curso
    li $v0, 4
    la $a0, selectcategory
    syscall
    
    li $v0, 4
    lw $a0, 8($t3)
    syscall
    
    li $v0, 4
    la $a0, return
    syscall
    
    j travelloop	     	     	     	     	     	     	     	     
error301:
   # Mostrar mensaje de error	 
    li $v0, 4
    la $a0, error
    syscall 
    
    li $v0, 1
    li $t1, 301
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, return
    syscall
                              
endlist:
   lw $ra, 0($sp)
   addiu $sp, $sp, 8
   jr $ra 
nextcategory:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    # Cargar la dirección de la categoría actual de la lista de categorías actuales
    lw $t0, wclist
    beqz $t0, error201  # Si no hay categoría actual, mostrar error

    # Obtener la dirección del siguiente nodo
    lw $t1, 12($t0)  # $t1 = siguiente nodo de la categoría actual
    beq $t1, $t0, error202  # si el siguiente es el mismo, dara error

    # Actualizar la categoría actual a la siguiente
    sw $t1, wclist

    # Mostrar mensaje de éxito
    la $a0, selCat
    li $v0, 4
    syscall
    
   # Cargar el nombre de la nueva categoría seleccionada 
   lw $t6, 8($t1) # $t6 = nombre de la categoría en el nuevo nodo seleccionado
    # Imprimir el nombre de la nueva categoría seleccionada 
   li $v0, 4 
   move $a0, $t6 
   syscall 
   
   li $v0, 4 
   la $a0, return 
   syscall
   
   j endselectcat

error201:
    # Mostrar mensaje de error
    li $v0, 4
    la $a0, error
    syscall 
    
    li $v0, 1
    li $t1, 201
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, return
    syscall
	
    j endselectcat
error202:
    # Mostrar mensaje de error
    li $v0, 4
    la $a0, error
    syscall 
    
    li $v0, 1
    li $t1, 202
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, return
    syscall          
endselectcat:
    lw $ra, 0($sp)
    addiu $sp, $sp, 4
    jr $ra	      
prevcategory:
    addiu $sp, $sp, -4
    sw $ra, 0($sp)

    # Cargar la dirección de la categoría actual de la lista de categorías actuales
    lw $t0, wclist
    beqz $t0, error201  # Si no hay categoría actual, mostrar error

    # Obtener la dirección del siguiente nodo
    lw $t1, 0($t0)  # $t1 = anterior nodo de la categoría actual
    beq $t1, $t0, error202  # si el siguiente es el mismo, dara error

    # Actualizar la categoría actual a la siguiente
    sw $t1, wclist
    # Mostrar mensaje de éxito
    la $a0, selCat
    li $v0, 4
    syscall
    
   # Cargar el nombre de la nueva categoría seleccionada 
   lw $t6, 8($t1) # $t6 = nombre de la categoría en el nuevo nodo seleccionado
    # Imprimir el nombre de la nueva categoría seleccionada 
   li $v0, 4 
   move $a0, $t6 
   syscall 
   
   li $v0, 4 
   la $a0, return 
   syscall
   
   j endselectcat
delcategory:
    addiu $sp, $sp, -8      # Reservar espacio en el stack
    sw $ra, 0($sp)          # Guardar valor de retorno
    sw $t0, 4($sp)          # Guardar categoría actual

    # Verificar si hay una categoría seleccionada
    lw $t0, wclist          # $t0 = categoría seleccionada
    beqz $t0, error401      # Error si no hay categoría seleccionada

    # Verificar si es la única categoría
    lw $t1, 12($t0)         # $t1 = siguiente nodo
    beq $t1, $t0, deleteonly # Si es la única categoría

    # Desconectar el nodo actual
    lw $t2, 0($t0)          # $t2 = nodo anterior
    lw $t3, 12($t0)         # $t3 = nodo siguiente
    sw $t3, 12($t2)         # Actualizar "next" del anterior
    sw $t2, 0($t3)          # Actualizar "prev" del siguiente

    # Si la categoría actual es la cabecera, moverla
    lw $t4, cclist          # $t4 = cabecera
    beq $t0, $t4, updateheader
     
    sw $t3, wclist          # $t3 = nueva categoria actual

    j freenode              # Liberar el nodo actual

updateheader:
    sw $t3, cclist          # Actualizar la cabecera a la siguiente categoría
    sw $t3, wclist          # Actualizar la categoria actual
    j freenode

deleteonly:
    # Si es la única categoría, vaciar la lista
    sw $zero, cclist        # Vaciar la lista de categorías
    sw $zero, wclist

freenode:
    # Agregar el nodo a la lista libre
    lw $t5, slist           # Cargar la lista libre
    sw $t5, 12($t0)         # "next" del nodo apunta a la lista libre
    sw $t0, slist           # Actualizar la lista libre

    # Decrementar el contador de categorías
    lw $t6, categorycount   # $t6 = contador actual
    addi $t6, $t6, -1       # Decrementar en 1
    sw $t6, categorycount

    # Mostrar mensaje de éxito
    la $a0, success
    li $v0, 4
    syscall
    j enddelcategory

error401:
    # Mostrar error si no hay categoría seleccionada
    li $v0, 4
    la $a0, error
    syscall

    li $v0, 1
    li $a0, 401             # Código de error 701 (sin categoría seleccionada)
    syscall

    li $v0, 4
    la $a0, return
    syscall
    j enddelcategory

enddelcategory:
    lw $ra, 0($sp)          # Restaurar valor de retorno
    lw $t0, 4($sp)          # Restaurar categoría actual
    addiu $sp, $sp, 8       # Restaurar el stack
    jr $ra                  # Retornar
    
addobject:
    addiu $sp, $sp, -8    # Reservar espacio en el stack
    sw $ra, 0($sp)        # Guardar valor de retorno

    # Verificar si hay una categoría seleccionada
    lw $t0, wclist        # $t0 = categoría seleccionada
    beqz $t0, error501

    # Verificar si hay espacio para nuevos objetos
    la $t1, objectcount  # $t1 = dirección del contador de objetos
    lw $t2, 0($t1)        # $t2 = contador de objetos
    li $t3, 64            # Máximo permitido de objetos
    bge $t2, $t3, nospaceobjects

    # Calcular la dirección del nuevo objeto
    la $t4, objectstorage  # $t4 = base de almacenamiento de objetos
    li $t5, 16              # Tamaño de cada nodo de objeto
    mul $t6, $t2, $t5       # Offset del nuevo objeto
    add $t7, $t4, $t6       # $t7 = dirección del nuevo objeto

    # Solicitar nombre del objeto
    li $v0, 4
    la $a0, objName
    syscall
    li $v0, 8
    la $a0, buffer
    li $a1, 49
    syscall

    # Asignar memoria para el nombre del objeto
    li $a0, 50
    li $v0, 9
    syscall
    move $t8, $v0           # $t8 = dirección de la memoria para el nombre

    # Copiar el nombre desde el buffer
    la $t9, buffer
copyobjectname:
    lb $t3, 0($t9)         # $t3 = byte actual del buffer
    sb $t3, 0($t8)         # Copiar byte a la memoria asignada
    beqz $t3, endcopyname
    addiu $t9, $t9, 1
    addiu $t8, $t8, 1
    j copyobjectname
endcopyname:    
    # Inicializar el nodo del objeto
    sw $zero, 12($t7)       # Siguiente (inicialmente nulo)
    sw $zero, 0($t7)       # Anterior (inicialmente nulo)
    sw $v0, 4($t7)         # Dirección del nombre del objeto
    li $t1, 1              
    sw $t1, 8($t7)         # por defecto el ID es 1

    # Obtener lista de objetos de la categoría seleccionada
    lw $t9, 4($t0)         # $t9 = dirección de la lista de objetos
    beqz $t9, addfirstobject

    # Conectar el nuevo objeto en la lista existente
    lw $t3, 0($t9)         # $t3 = último nodo
    sw $t3, 0($t7)         # "prev" del nuevo nodo apunta al último
    sw $t7, 12($t3)        # "next" del último apunta al nuevo nodo
    sw $t9, 12($t7)        # "next" del nuevo apunta al primero
    sw $t7, 0($t9)         # "prev" del primero apunta al nuevo nodo
    lw $t1, 8($t3)         # $t1 = ID del ultimo nodo
    addi $t1, $t1, 1       # incrementamos el ID en uno
    sw $t1, 8($t7)         # lo insertamos en el nuevo nodo 
    j updateobjectcount

addfirstobject:
    # Si la lista está vacía, inicializarla
    sw $t7, 4($t0)         # Actualizar lista de objetos de la categoría
    sw $t7, 0($t7)         # "prev" apunta a sí mismo
    sw $t7, 12($t7)        # "next" apunta a sí mismo

updateobjectcount:
    # Incrementar el contador de objetos
    lw $t2, objectcount   # $t2 = contador actual
    addiu $t2, $t2, 1      # Incrementar contador
    sw $t2, objectcount

    # Mostrar mensaje de éxito
    la $a0, success
    li $v0, 4
    syscall
    j endaddobject

nospaceobjects:
    # Mostrar error por falta de espacio
    la $a0, error
    li $v0, 4
    syscall

endaddobject:
    lw $ra, 0($sp)         # Restaurar $ra
    addiu $sp, $sp, 8      # Restaurar el stack
    jr $ra                 # Retornar

error501:
    # Mostrar error si no hay categoría actual
    li $v0, 4
    la $a0, error
    syscall

    li $v0, 1
    li $a0, 501              # Código de error 501 (sin categoría)
    syscall

    li $v0, 4
    la $a0, return
    syscall
    j endaddobject                     
listobject:
    addiu $sp, $sp, -8    # Reservar espacio en el stack
    sw $ra, 0($sp)        # Guardar valor de retorno

    # Verificar si hay una categoría seleccionada
    lw $t0, wclist        # $t0 = categoría seleccionada
    beqz $t0, error601

    # Cargar la lista de objetos de la categoría seleccionada
    lw $t1, 4($t0)        # $t1 = dirección de la lista de objetos
    beqz $t1, error602

    # Recorrer la lista de objetos
    move $t2, $t1         # $t2 = nodo actual (inicialmente el primero)
    move $t3, $t1 
printobjectloop:
    # Imprimir el nombre del objeto actual
    lw $t4, 4($t2)        # $t4 = dirección del nombre del objeto
    li $v0, 4
    move $a0, $t4
    syscall

    # Imprimir un salto de línea
    li $v0, 4
    la $a0, return
    syscall

    # Moverse al siguiente objeto
    lw $t2, 12($t2)       # $t2 = siguiente nodo
    #beq $t2, $t1, endlistobjects  # Si regresamos al primero, terminamos
    bne $t2, $t1, printobjectloop
    #j printobjectloop
    j endlistobjects

noobjectsincategory:
    # Mensaje de error si no hay objetos en la categoría
    li $v0, 4
    la $a0, error
    syscall

    li $v0, 4
    la $a0, return
    syscall
endlistobjects:
    lw $ra, 0($sp)      
    addiu $sp, $sp, 8    
    jr $ra                
	     	     	     	     	     	     	     	     
error601:	     	     	     	     	     	     	     	     
   # Mostrar mensaje de error	 
    li $v0, 4
    la $a0, error
    syscall 
    
    li $v0, 1
    li $t1, 601
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, return
    syscall
    
    j endlist
error602:	     	     	     	     	     	     	     	     
   # Mostrar mensaje de error	 
    li $v0, 4
    la $a0, error
    syscall 
    
    li $v0, 1
    li $t1, 602
    move $a0, $t1
    syscall
    
    li $v0, 4
    la $a0, return
    syscall
    
    j endlist                               

delobject:
    addiu $sp, $sp, -8      # Reservar espacio en el stack
    sw $ra, 0($sp)          # Guardar valor de retorno

    # Verificar si hay una categoría seleccionada
    lw $t0, wclist          # Cargar categoría seleccionada
    beqz $t0, error701      # Si no hay categoría, mostrar error

    # Obtener la lista de objetos de la categoría seleccionada
    lw $t1, 4($t0)          # Cargar la dirección de la lista de objetos
    beqz $t1, error702      # Si no hay objetos, mostrar error
    

    # Solicitar el ID del objeto a eliminar
    li $v0, 4
    la $a0, idObj
    syscall
    li $v0, 5
    syscall
    move $t2, $v0           # Guardar ID del objeto a eliminar

    # Buscar el objeto con el ID proporcionado
    move $t3, $t1           # Puntero a la lista de objetos

find_object:
    lw $t5, 8($t3)          # Cargar ID del objeto
    beq $t5, $t2, delete_object   # Si se encontró el objeto, eliminarlo
    lw $t3, 12($t3)         # Avanzar al siguiente objeto
    lw $t4, 4($t0)
    beq $t3, $t4, notfoundobject      # Si se llegó al principio de la lista, el objeto no existe
    j find_object

delete_object:
    # Eliminar el objeto de la lista
    lw $t4, 12($t3)
    beq $t4, $t3, deleteonlyobj
    
    lw $t6, 0($t3)          # Cargar el nodo anterior
    lw $t7, 12($t3)         # Cargar el nodo siguiente
    
    # Actualizar los punteros de los nodos adyacentes
    sw $t7, 12($t6)          # El anterior apunta al siguiente
    sw $t6, 0($t7)           # El siguiente apunta al anterior
    
    lw $t4, 4($t0)           # Tomo la direccion de la lista de objetos
    beq $t3, $t4, updatehead # Si el primer objeto de la lista es igual al objeto que eliminamos actualizamos la propia lista
    
    
    j freenode

deleteonlyobj:
    sw $zero, 4($t0)              
    j freenode        

updatehead:
    sw $t7, 4($t0)          # El siguiente del primer objeto pasa a ser el primero de la lista

freenodeobj:                
    # Agregar el objeto a la lista de objetos libres
    lw $t9, slist
    sw $t9, 12($t3)         # Conectar el objeto a la lista libre
    sw $t3, slist           # Actualizar la lista libre

    # Decrementar el contador de objetos
    lw $t0, objectcount
    addi $t0, $t0, -1
    sw $t0, objectcount

    # Mostrar mensaje de éxito
    la $a0, success
    li $v0, 4
    syscall

    lw $ra, 0($sp)          # Restaurar valor de retorno
    addiu $sp, $sp, 8       # Restaurar el stack
    jr $ra                  # Retornar

error701:
    # Mostrar error si no hay categoría seleccionada
    li $v0, 4
    la $a0, error
    syscall
    li $v0, 1
    li $a0, 701
    syscall
    li $v0, 4
    la $a0, return
    syscall
    j end_delobject

error702:
    # Mostrar error si no hay objetos en la categoría seleccionada
    li $v0, 4
    la $a0, error
    syscall
    li $v0, 1
    li $a0, 702
    syscall
    li $v0, 4
    la $a0, return
    syscall
    j end_delobject

notfoundobject:
    # Mostrar error si el objeto no se encuentra
    li $v0, 4
    la $a0, error
    syscall
    li $v0, 4
    la $a0, errorobject
    syscall
    li $v0, 4
    la $a0, return
    syscall
    j end_delobject

end_delobject:
    lw $ra, 0($sp)
    addiu $sp, $sp, 8
    jr $ra
