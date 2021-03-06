jQuery(document).ready(function($) {
	var roles = [
		{ id: '', name: '' },
		{ id: 'user', name: 'Пользователь' },
		{ id: 'manager', name: 'Менеджер' },
		{ id: 'admin', name: 'Администратор' }
	];
	var metadata = {
		categories: [
			//{ width: '30px', editing: 0, name: 'id', type: 'number', title: 'ID'},
			{ name: 'name', type: 'text', title: 'Название'},
			//{ name: 'location', type: 'text', title: 'Положение'},
			{ type: 'control' }
		], 
		items: [
			{ width: '30px', editing: 0, name: 'id', type: 'number', title: 'Артикул'},
			{ name: 'name', type: 'text', title: 'Название'},
			{ width: '30px', name: 'price', type: 'number', title: 'Стоимость'},
			{ width: '30px', name: 'category_id', type: 'select', title: 'Категория', tableName: 'categories', valueField: 'id', textField: 'name' },
			{ type: 'control' }
		],
		items_stores: [
			{ width: '30px', editing: 0, name: 'item_id', type: 'number', title: 'Артикул' },
			{ editing: 0, name: 'store_id', type: 'select', title: 'Магазин', tableName: 'stores', valueField: 'id', textField: 'name' },
			{ name: 'count', type: 'number', title: 'Количество' },
			{ type: 'control' }
		],
		users_stores: [
			{ editing: 0, name: 'user_id', type: 'select', title: 'Пользователь', tableName: 'users', valueField: 'id', textField: 'email' },
			{ editing: 0, name: 'store_id', type: 'select', title: 'Магазин', tableName: 'stores', valueField: 'id', textField: 'name' },
			{ type: 'control', editButton: false }
		],
		statuses: [
			{ name: 'name', type: 'text', title: 'Название'},
			{ type: 'control' }
		],
		orders: [
			{ name: 'user_id', editing: 0, type: 'select', title: 'Пользователь', tableName: 'users', valueField: 'id', textField: 'email' },
			//{ name: 'items', type: 'text', title: 'Товары'},
			{ name: 'status_id', type: 'select', title: 'Статус', tableName: 'statuses', valueField: 'id', textField: 'name' },
			{ name: 'comment', type: 'textarea', title: 'Комментарий'},
			{ name: 'createtime', type: 'text', title: 'Время создания'},
			{ name: 'address', type: 'textarea', title: 'Адрес доставки'},
			{ name: 'payment', type: 'textarea', title: 'Способ оплаты'},
			{ name: 'hidden', type: 'checkbox', title: 'Скрыто'},
			{ type: 'control' }
		],
		stores: [
			{ name: 'name', type: 'text', title: 'Название'},
			{ type: 'control' }
		],
		users: [
			{ name: 'role', type: 'select', title: 'Роль', items: roles, valueField: 'id', textField: 'name' },
			{ name: 'email', type: 'text', title: 'E-Mail'},
			{ name: 'name', type: 'text', title: 'Имя'},
			{ name: 'sname', type: 'text', title: 'Фамилия'},
			{ name: 'address', type: 'textarea', title: 'Адрес доставки'},
			{ name: 'payment', type: 'textarea', title: 'Способ оплаты'},
			{ type: 'control' }
		]
	};
	$('.grid-tables li a').click(function() {
		$('.grid-tables .active').removeClass('active');
		var tableName = $(this).parent().addClass('active').data('table');
		var requestCount = 0;
		var noSelectFields = true;
		metadata[tableName].forEach(function(field){
			if (field.type == 'select' && field.tableName) {
				noSelectFields = false;
				requestCount++;
				$.getJSON('/cabinet/admin/reference', {
					table: field.tableName,
					valueField: field.valueField,
					textField: field.textField
				}, function(data){
					data.unshift({ id: 0, name: '' });
					field.items = data;
					requestCount--;
					if (!requestCount) RebuildGrid(tableName);
				}).error(networkError);
			}
		});
		if (noSelectFields) RebuildGrid(tableName);
	}).filter(window.location.hash ? '[href=' + window.location.hash + ']' : '*').first().trigger('click');
	
	var grid;
	function RebuildGrid(tableName) {
		if (grid) $("#grid").jsGrid("destroy");
		$.ajaxSetup({
			url: '/cabinet/admin/ajax?table=' + tableName,
			dataType: 'json',
			error: networkError
		});
		grid = $('#grid').jsGrid({
			fields: metadata[tableName],
			controller: {
				loadData: function(filter) {
					return $.ajax({ type: 'GET', data: filter });
				},
				insertItem: function(item) {
					return $.ajax({ type: 'POST', data: item });
				},
				updateItem: function(item) {
					return $.ajax({ type: 'PUT', data: item });
				},
				deleteItem: function(item) {
					$.ajax({ type: 'DELETE', dataType: 'html', data: item });
				}
			}
		});
	}
});