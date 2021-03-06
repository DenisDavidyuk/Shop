﻿package Shop::Admin;
use Dancer ':syntax';
use Shop::DB;
use Shop::Common;
use utf8;
use Shop::Schema;

use Dancer::Plugin::Ajax;
use Shop::Categories;
use JSON qw//;

prefix '/cabinet/admin';

my $menu = [
	{name => 'Редактирование таблиц', href => '/cabinet/admin'},
	{name => 'Редактирование категорий', href => '/cabinet/admin/categories'},
	{name => 'Создание отчётов', href => '/cabinet/admin/report'}
];

#use Shop::Admin::Tables;
get 'table' => sub {
	template 'cabinet/admin/grid', {
		tables => [
			{name => 'Товары', table => 'items'},
			{name => 'Категории', table => 'categories'},
			{name => 'Пользователи', table => 'users'},
			{name => 'Заказы', table => 'orders'},
			{name => 'Статусы', table => 'statuses'},
			{name => 'Менеджеры', table => 'users_stores'},
			{name => 'Магазины', table => 'stores'},
			{name => 'Товары в магазинах', table => 'items_stores'}
		],
		menu => $menu
	};
};

ajax '/table' => sub {
  if (request->is_post) {
    return status 400 unless isParamNEmp('table') && $metadata->{param('table')};
	  my $source = Shop::Schema->source($metadata->{param('table')});
	  my $item = {};
	  foreach ($source->columns) {
	  	next unless defined param($_) && param($_);
		  $item->{$_} = param($_);
	  }
	  return JSON::to_json {
		  db()->resultset($metadata->{param('table')})
			  ->create($item)
			  ->get_columns
	    };
  } else {
    return status 400 unless isParamNEmp('table') && $metadata->{param('table')};
    my $source = Shop::Schema->source($metadata->{param('table')});
    my $where = {};
    my $sortFIeldValid = false;
    foreach ($source->columns) {
      $sortFIeldValid ||= isParamEq('sortField', $_);
      next unless defined param($_) && param($_);
      if ($_ eq 'id' || $_ eq 'role' || isParamUInt($_)) {
        $where->{$_} = param($_);
      } else {
        $where->{$_} = { like => '%'.param($_).'%' };
      }
    }
    my $is_page = isParamUInt('pageSize') && isParamUInt('pageIndex');
    my $rs = db()->resultset($metadata->{param('table')})->search($where, {
      $is_page ?
        ( rows => param('pageSize'), page => param('pageIndex') ) : (),
      $sortFIeldValid ?
        ( order_by => { isParamEq('sortOrder', 'desc') ? -desc : -asc => param('sortField') } )
      : ()
    });
    $rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    return JSON::to_json {data => [$rs->all()], itemsCount => $rs->pager()->total_entries } if $is_page;
    return JSON::to_json [$rs->all()];
  }
};

put '/table' => sub {
	return status 400 unless isParamNEmp('table') && $metadata->{param('table')};
	my $source = Shop::Schema->source($metadata->{param('table')});
	my $item = {};
	$item->{$_} = param($_) foreach ($source->columns);
	return JSON::to_json {
		db()->resultset($metadata->{param('table')})
			->find(param('id'))->update($item)
			->get_columns
	};
};

del '/table' => sub {
	return status 400 unless isParamNEmp('table') && $metadata->{param('table')};
	my $source = Shop::Schema->source($metadata->{param('table')});
	my $where = {};
	$where->{$_} = param($_) foreach ($source->columns);
	db()->resultset($metadata->{param('table')})->search($where, undef)->delete_all();
	return '';
};

get '/reference' => sub {
	return status 400 unless isParamNEmp('table') && isParamNEmp('valueField')
		&& isParamNEmp('textField') && $metadata->{param('table')};
	my $rs = db()->resultset($metadata->{param('table')})->search(undef, {
		select => [param('valueField'), param('textField')],
		order_by => param('textField')
	});
	$rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
	return JSON::to_json [$rs->all()];
};
#use Shop::Admin::Categories;
get '/categories' => sub {
    template 'cabinet/admin/categories', {
		menu => $menu
	};
};

ajax '/categories' => sub {
	unless (request->is_post) {
		return JSON::to_json Shop::Categories::getTree(true);
	} else {
		my $parent;
		return 'Ошибка' unless isParamNEmp('name')
			&& isParamUInt('parent_id') && ($parent = db()->resultset('Category')->find(param('parent_id')));
		Shop::Categories::resetTree;
		return db()->resultset('Category')->create({
			name => param('name'),
			location => $parent->location . ',' . param('parent_id')
		})->id;
	}
};

put '/categories' => sub {
	my ($node, $parent);
	return 'Ошибка' unless isParamNEmp('name')
		&& isParamUInt('parent_id') && ($parent = db()->resultset('Category')->find(param('parent_id')))
		&& isParamUInt('id') && ($node = db()->resultset('Category')->find(param('id')));
	$node->name(param('name'));
	my $new_location = $parent->location . ',' . param('parent_id');
	if ($node->location ne $new_location) {
		my $rs = db()->resultset('Category')->search({
			-or => {
				'location' => { like => $node->location.'.%' },
				'location' => $node->location
			}
		});
		while (my $child = $rs->next) {
			my $str = $child->location;
			substr($str, 0, strlen($node->location)) = $new_location;
			$child->location($str);
			$child->update;
		}
		$node->location($new_location);
	}
	$node->update;
	Shop::Categories::resetTree;
	return '';
};

del '/categories' => sub {
	my ($node, $parent);
	return 'Ошибка' unless isParamNEmp('name')
		&& isParamUInt('id') && ($node = db()->resultset('Category')->find(param('id')));
	return 'Ошибка: Узел имеет дочерние категории' if getCategoriesIds($node->id);
	return 'Ошибка: Существуют товары связанные с текущей или дочерними категориями' if db()->resultset('Items')->search({
		category_id => getCategoriesIds($node->id)
	})->single;
	$node->delete;
	Shop::Categories::resetTree;
	return '';
};

hook before_template_render => sub {
	var menu_admin => $menu;
};

hook before => sub {
	unless (request->path_info !~ /^\/cabinet\/\/admin/ || session('role') eq 'admin') {
		addMessage('Отсутствуют необходимые права доступа.', 'danger');
		status 403;
		return redirect session('path_info');
	}
};

hook before_template => sub {
	addUserMenuItem({name => 'Управление сайтом', href => '/cabinet/admin', icon => 'glyphicon-wrench'})
		if session('role') eq 'admin';
};

get '' => sub {
	redirect 'table';
};

get '/report' => sub {
    template 'cabinet/admin/report';
};

my $metadata = {
	categories => 'Category',
	items  => 'Item',
	items_stores  => 'ItemsStore',
	users_stores  => 'UsersStore',
	orders  => 'Order',
	statuses  => 'Status',
	stores  => 'Store',
	users  => 'User'
};

prefix undef;

true;
