.data
slist:	.word 0
cclist: .word 0
wclist: .word 0
schedv: .space 32

menu:	.ascii "Colecciones de objetos categorizados\n"
		.ascii "====================================\n"
		.ascii "1-Nueva categoria\n"
		.ascii "2-Siguiente categoria\n"
		.ascii "3-Categoria anterior\n"
		.ascii "4-Listar categorias\n"
		.ascii "5-Borrar categoria actual\n"
		.ascii "6-Anexar objeto a la categoria actual\n"
		.ascii "7-Listar objetos de la categoria\n"
		.ascii "8-Borrar objeto de la categoria\n"
		.ascii "0-Salir\n"
		.asciiz "Ingrese la opcion deseada: "
error:	.asciiz "Error: "
return:	.asciiz "\n"
catName:.asciiz "\nIngrese el nombre de una categoria: "
selCat:	.asciiz "\nSe ha seleccionado la categoria:"
idObj:	.asciiz "\nIngrese el ID del objeto a eliminar: "
objName:.asciiz "\nIngrese el nombre de un objeto: "
success:.asciiz "La operación se realizo con exito\n\n"
selCatArrow: .asciiz ">" 


.text
main:

	la $t0, schedv	#Cargar la direccion del vector de punteros 
	la $t1, newcaterogy
	sw $t1, 0($t0)
	la $t1, nextcategory
	sw $t1, 4($t0)
	la $t1, prevcaterogy
	sw $t1, 8($t0)
	la $t1, listcategories
	sw $t1, 12($t0)
	la $t1, delcaterogy
	sw $t1, 16($t0)
	la $t1, newobject
	sw $t1, 20($t0)
	la $t1, listobjects
	sw $t1, 24($t0)
	la $t1, delobject
	sw $t1, 28($t0)
	
main_loop:
	#muestra el menu
	jal menu_display
	beqz $v0, main_end #si el usuario llega a ingresar 0 se termina
	addi $v0, $v0, -1  # ajusta indice del menu
	sll $v0, $v0, 2    # multiplica la opcion de menu por 4 
	la $t0, schedv	   #carga la direccion de la etiqueta en el registro $t0 
	add $t0, $t0, $v0  #coloca en el registro $t0 el valor de $v0 
	lw $t1, 0($t0)      #carga en el registro $t1 el primer valor de $t0 
        la $ra, main_ret   #save return address
        jr $t1		   #call menu subrutine
main_ret:
        j main_loop		
main_end:
	j done

menu_display: 
	#muestro el menu 
	li $v0, 4	#syscall para imprimir string 
	la $a0, menu	#cargar la dirección del texto del menu 
	syscall
	
	li $v0, 5 #lee un entero del usuario 
	syscall 
	
	
	# test if invalid option go to L1
	bgt $v0, 8, menu_display_L1
	bltz $v0, menu_display_L1
	# else return
	jr $ra
	# print error 101 and try again
	
	
menu_display_L1:
	#imprimir mensaje de error
	li $v0, 4
	la $a0, error 
	syscall 
	
	li $v0, 1 
	la $a0, 101 
	syscall 
	
	li $v0, 4 
	la $a0, return 
	syscall 
	j menu_display 

newcaterogy:
	addiu $sp, $sp, -4
	sw $ra, 4($sp)
	la $a0, catName		# input category name
	jal getblock
	move $a2, $v0		# $a2 = *char to category name
	la $a0, cclist		# $a0 = list
	li $a1, 0			# $a1 = NULL
	jal addnode
	lw $t0, wclist
	bnez $t0, newcategory_end
	sw $v0, wclist		# update working list if was NULL
newcategory_end:
	li $v0, 0			# return success
	lw $ra, 4($sp)
	addiu $sp, $sp, 4
	jr $ra

nextcategory: 
	#verificar si hay categorias 
	#wclist almacena la direccion de la categoria saleccionada 
	lw $t0, wclist #carga la direccion de la lista de categorías 
	beqz $t0, error201 #si la lista esta vacia, no hay categorias, va a la funcion  error201 y muestra error202 
	
	#verificar si hay una sola categoria 
	lw $t1, 12 ($t0) #cargar el siguiente nodo de la lista (si existe) 
	beq $t1, $t0, error202 #si hay siguiente nodo, salta a la funcion error202, y muestra por pantalla error202
	
	#mover al siguiente nodo 
	sw $t1, wclist #actualizar la lista actual 
	
	#imprimir la categoria seleccionada 
	la $a0, selCat #carga el mensaje se ha seleccionado la categoria 
	li $v0, 4 #sylscall para imprimir string 
	syscall 
	
	 
	lw $a0, 8($t1) #carga el nombre de la catagoría 
	li $v0, 4 #syscall para imprimir string 
	syscall 
	jr $ra 
	
error201: 
	#si la lista esta vacia mostrar error 201 
	li $v0, 4 #muestra en pantalla un string 
	la $a0, error #muestra el msj de error
	syscall 
	li $v0, 1 #muestro en pantalla un entero 
	li $a0, 201 #muestro el 201
	syscall	
	li $v0, 4
	la $a0, return #carga la etiqueta return que tiene adentro \n
	syscall
	jr $ra #regresar al menu
	
error202: 
	#si la lista esta vacia mostrar error 202 
	li $v0, 4 #muestra en pantalla un string 
	la $a0, error #muestra el msj de error 
	syscall 
	li $v0, 1 #muestro en pantalla un entero 
	li $a0, 202 #muestro el 202 
	syscall
	li $v0, 4
	la $a0, return # carga la etiqueta return que tiene adentro "\n"
	syscall
	jr $ra #regresar al menu 
	

prevcaterogy:
	#verifico si hay categorias 
	lw $t0, wclist #cargo la categoria actual en $t0 
	beqz $t0, error201 #si no hay categorias (wclist es 0), muestra error 201 
	
	#reviso si hay una sola categoria 
	lw $t1, 0($t0) #cargo el puntero al nodo anterior 
	beq $t0, $t1, error202 #si vuelve para atras hay una sola caegoria, muestra error 202
	
	#moverse a la categoria anterior 
	sw $t1, wclist #actualizo wclist para que apunte a la categoria anterior 
	
	#muestro mensaje de categoria seleccionada 
	la $a0, selCat #cargo el msj "se ha seleccinado la categoria"
	li $v0, 4      #llamo syscall para imprimir texto 
	syscall 
	 
	lw $a0, 8($t1) #caraga el nombre de la categoria (guardado en el nodo) 
	li $v0, 4	#llamo al syscall para imprimir texto 
	syscall 	
	jr $ra #regreso al menu principal 
	


listcategories:
	 #Verficar si hay categorias 
	 lw $t0, wclist #cargar la direccion de la categoria seleccionada en $t0
	 beqz $t0, error301 #si wclist es 0, no hay categorias, ir al error 301 
	 
	 #comenzar a recorrer la lista circular 
	 move $t1, $t0 #guardar el nodo inicial en $t1
	 
buscador: 
	#imprimir ">" si es la categoria seleccionada 
	lw $t2, wclist #cargar la categoria seleccionada en $t2 
	beq $t1, $t2, imprimirflecha #si $t1 es igual a $t2, imprimir ">"
	j omitirflecha #si no es la seleccionada saltar 
	
imprimirflecha: 
	li $v0, 4 #syscall para imprimir texto 
	la $a0, selCatArrow #Cargar el símbolo ">" como string 
	syscall
	
omitirflecha: 
	#Imprimir el nombre de la categoría 
	lw $a0, 8($t1) #Cargar el nombre de la categoría desde el nodo actual 
	li $v0, 4 #syscall para imrprimir texto 
	syscall 
	
	#moverse al siguiente nodo
	lw $t1, 12($t1) #cargar la direccion del siguiente nodo en $t1
	bne $t1, $t0, buscador #si no hemos vuelto al nodo inicial, repetir el bucle 
	jr $ra #regresar al menú principal 
	
error301: 
	#Mostrar error 301: No hay categorías 
	li $v0, 4 #syscall para imprimir texto 
	la $a0, error #cargar el mensaje de error base
	syscall 
	li $v0, 1 #syscall para imprimir entero 
	li $a0, 301 #código de error 
	syscall 
	li $v0, 4 #syscall para imprimir retorno de línea 
	la $a0, return #cargar "\n"
	syscall 
	jr $ra #regresar al menu pricipal 


delcaterogy:
	#Verificar si hay categorias 
	lw $t0, wclist 
	beqz $t0, error201 #si no ay categorias, error 201 
	
	#guardar la direccion de la categoría actual 
	move $a0, $t0 
	la $a1, cclist 
	jal delnode #eliminar el nodo actual de la lista 
	
	#verificar si la lista quedó vacía 
	lw $t1, cclist 
	beqz $t1, delcat_empty 
	sw $t1, wclist #actualizar wclist a la siguiente categoria 
	j delcat_end 
	
delcat_empty: 
	sw $zero, wclist #si no hay más categorías, limpiar wclist 

delcat_end:
	li $v0, 0 #operacion exitosa
	jr $ra 

newobject: 

	# Reservar espacio en el stack y guardar el valor de $ra
 	addiu $sp, $sp, -8
	sw $ra, 4($sp)
	sw $s0, 0($sp) # Guardar $s0 por seguridad

	# Cargar la categoría seleccionada
	lw $s0, wclist           # $s0 = dirección de la categoría seleccionada
	beqz $s0, no_category    # Si no hay categoría seleccionada, mostrar error

	#Solicitar el nombre del nuevo objeto
	la $a0, objName          # Texto: "Ingrese el nombre de un objeto:"
	jal getblock             # Leer entrada del usuario y reservar memoria
	move $a2, $v0            # Guardar el puntero al nombre en $a2

	# Determinar el ID para el nuevo objeto
	la $t0, 4($s0)           # $t0 apunta al primer puntero de la categoría (lista de objetos)
  	lw $t1, ($t0)            # $t1 obtiene la dirección del primer nodo
	beqz $t1, assign_first_id # Si no hay objetos, asignar el ID inicial

	# Calcular el nuevo ID basado en el último objeto
	assign_new_id:
	lw $t1, ($t1)            # Recorrer la lista de objetos (enlace al siguiente nodo)
	bnez $t1, assign_new_id  # Continuar hasta encontrar el último nodo
	lw $a1, 4($t1)           # Cargar el ID del último nodo en $a1
	addi $a1, $a1, 1         # Incrementar el ID para el nuevo objeto
	j create_node            # Saltar a la creación del nodo

	# Caso especial: asignar el primer ID
	assign_first_id:
	li $a1, 1                # Establecer el primer ID en 1
	
	# Crear el nuevo nodo
	create_node:
	jal addnode              # Llamar a la función para crear el nodo
	j finish_newobject       # Ir al final de la subrutina

	# Mostrar error si no hay categoría seleccionada
	no_category:
	li $v0, 4
	la $a0, error            # Imprimir "Error:"
	syscall
	li $v0, 1
	li $a0, 501              # Mostrar el código de error "501"
	syscall
	j restore_state          # Restaurar el estado y salir

 	# Finalizar la subrutina
	finish_newobject:
	li $v0, 4
	la $a0, success          # Imprimir "Operación exitosa"
	syscall

	# Restaurar el estado
	restore_state:
 	lw $s0, 0($sp)           # Restaurar el valor de $s0
 	lw $ra, 4($sp)           # Restaurar $ra
	addiu $sp, $sp, 8        # Liberar espacio en el stack
	li $v0, 0                # Indicar éxito
	jr $ra                   # Regresar 
	

listobjects:
	lw $t0, wclist     #cargar la categoria actual 
	beqz $t0, error201 #Si no hay categorias seleccionada,error 201 
	lw $t1, 4($t0)     #cargar la lista de objetos a la categoria 
	beqz $t2, error301 #si no hay objetos, eror 301 

listobj_loop: 
	#Imprimir el nombre del objeto 
	lw $a0, 8($t1)
	li $v0, 4 
	syscall
	
	#moverse al siguiente objeto 
	lw $t1, 12($t1)
	bne $t1, $zero, listobj_loop
	jr $ra	

delobject:
	la $a0, idObj      #pedir el ID del objeto a eliminar 
	jal getblock 
	move $t1, $v0      #guardar direccion del bloque ingresado 
	lw $t0, wclist     #cargar la categoria actual 
	beqz $t0, error201 #si no hay categoria seleccionada, error 201
	lw $a1, 4($t0)     #cargar la lista de objetos de la categoria 
	
delobj_loop:
	lw $t2, 8($a1)             #cargar el nombre del objeto 
	beq $t2, $t1, delobj_found #si coincide el ID ingresado, eliminar 
	lw $a1, 12($a1)            #moverse al siguiente objeto 
	bnez $a1, delobj_loop 
	jr $ra                     #si no se encuentra, regresar 
	
delobj_found: 
	move $a0, $a1 #Configurar el nodo a eliminar 
	jal delnode   #Eliminar nodo	
	jr $ra 	




# a0: list address
# a1: NULL if category, node address if object
# v0: node address added
addnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	jal smalloc
	sw $a1, 4($v0) # set node content
	sw $a2, 8($v0)
	lw $a0, 4($sp)
	lw $t0, ($a0) # first node address
	beqz $t0, addnode_empty_list
addnode_to_end:
	lw $t1, ($t0) # last node address
 	# update prev and next pointers of new node
	sw $t1, 0($v0)
	sw $t0, 12($v0)
	# update prev and first node to new node
	sw $v0, 12($t1)
	sw $v0, 0($t0)
	j addnode_exit
addnode_empty_list:
	sw $v0, ($a0)
	sw $v0, 0($v0)
	sw $v0, 12($v0)
addnode_exit:
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra

# a0: node address to delete
# a1: list address where node is deleted
delnode:
	addi $sp, $sp, -8
	sw $ra, 8($sp)
	sw $a0, 4($sp)
	lw $a0, 8($a0) # get block address
	jal sfree      # free block
	lw $a0, 4($sp) # restore argument a0
	lw $t0, 12($a0) # get address to next node of a0 node
	beq $a0, $t0, delnode_point_self
	lw $t1, 0($a0) # get address to prev node
	sw $t1, 0($t0)
	sw $t0, 12($t1)
	lw $t1, 0($a1) # get address to first node again
	bne $a0, $t1, delnode_exit
	sw $t0, ($a1)  # list point to next node
	j delnode_exit
delnode_point_self:
	sw $zero, ($a1) # only one node
delnode_exit:
	jal sfree
	lw $ra, 8($sp)
	addi $sp, $sp, 8
	jr $ra

 # a0: msg to ask
 # v0: block address allocated with string
getblock:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	li $v0, 4
	syscall
	jal smalloc
	move $a0, $v0
	li $a1, 16
	li $v0, 8
	syscall
	move $v0, $a0
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra

smalloc:
	lw $t0, slist
	beqz $t0, sbrk
	move $v0, $t0
	lw $t0, 12($t0)
	sw $t0, slist
	jr $ra
sbrk:
	li $a0, 16 # node size fixed 4 words
	li $v0, 9
	syscall # return node address in v0
	jr $ra

sfree:
	lw $t0, slist
	sw $t0, 12($a0)
	sw $a0, slist # $a0 node address in unused list
	jr $ra 

done: 
	li $v0,10
	syscall 

