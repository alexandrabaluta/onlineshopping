pragma solidity ^0.4.24;


contract OnlineShopping {
        uint delivery_fee = 1;
        uint clothes_cost = 5;
        uint courier_count = 0;
        uint shop_count = 0;
        uint customer_count = 0;
        uint order_count = 0;
        uint time_limit = 5;
        enum OrderStatus {ordered, accepted, courier_found, prepared, picked, delivered}

        struct Customer {
            uint id;
            uint cur_order;
            uint last_order;
        }

        struct Shop {
            uint id;
            uint loc_x;
            uint loc_y;
            uint[] clothes;
            uint avg_rating;
            uint order_count;
        }

        struct Courier {
            uint id;
            uint cur_order;
            uint loc_x;
            uint loc_y;
            uint avg_rating;
            uint order_count;
        }

        struct Order {
            uint id;
            uint[] items;
            uint price;
            uint shop;
            uint del;
            uint cust;
            OrderStatus status;
            uint del_rating;
            uint shop_rating;
            uint time;
        }

        mapping(uint => Customer) customer_details;
        mapping(uint => Shop) shop_details;
        mapping(uint => Courier) courier_details;
        mapping(uint => Order) order_details;

        mapping(address => uint) get_shop_id;
        mapping(address => uint ) get_courier_id;
        mapping(address => uint) get_customer_id;


        /* ---------------EVENTS----------------- */

        event order_update(uint order_id, OrderStatus status);

        /* ---------------MODIFIERS-------------- */

        modifier is_customer() {
            require(get_customer_id[msg.sender] > 0, "You aren't registered");
            _;
        }

        modifier is_courier() {
            require(get_courier_id[msg.sender] > 0, "You aren't registered");
            _;
        }

        modifier is_shop() {
            require(get_shop_id[msg.sender] > 0, "You aren't registered");
            _;
        }

        modifier has_ordered() {
            require(customer_details[get_customer_id[msg.sender]].cur_order != 0, "You don't have any active orders");
            _;
        }

        /* ---------------UTILITY FUNCTIONS------ */

        function OnlineShopping() public  {

        }

        function item_exists(uint item, uint shop_id)
        public view returns(bool) {
                uint i;
        for (i = 0; i < shop_details[shop_id].clothes.length; i++) {
            if (shop_details[shop_id].clothes[i] == item) {
                return true;
            }
        }
        return false;
}

        /* ---------------REGISTRATION----------- */

        function register_customer() 
public returns(bool) {
            require(get_customer_id[msg.sender] == 0, "Customer already registered");
            customer_count++;
            Customer storage c = customer_details[customer_count];
            c.id = customer_count;
            c.cur_order = 0;
            customer_details[c.id] = c;
            get_customer_id[msg.sender] = c.id;
            return true;
        }

        function register_shop() 
public returns(bool) {
            require(get_shop_id[msg.sender] == 0, "Shop already registered");

            shop_count++;
            Shop storage s = shop_details[shop_count];
            s.id = shop_count;
            s.loc_x = 7;
            s.loc_y = 7;
            s.clothes.push(1);
            s.clothes.push(2);
            s.clothes.push(3);
            s.clothes.push(4);
            s.clothes.push(5);
            shop_details[s.id] = s;
            get_shop_id[msg.sender] = s.id;
            return true;
        }

        function register_courier() 
public returns(bool) {
            require(get_courier_id[msg.sender] == 0, "Courier already registered");

            courier_count++;
            Courier storage c = courier_details[courier_count];
            c.id = courier_count;
            c.loc_x = 7;
            c.loc_y = 7;
            courier_details[c.id] = c;
            get_courier_id[msg.sender] = c.id;
            return true;
        }

        function get_id()
        public view returns(uint) {
                uint id;
        id = get_customer_id[msg.sender];
        if (id != 0)
            return id;

        id = get_courier_id[msg.sender];
        if (id != 0)
            return id;

        id = get_shop_id[msg.sender];
        if (id != 0)
            return id;

        require(id != 0, "You aren't registered");
        return 0;
}

        /* ---------------CUSTOMER--------------- */

        function place_order(uint[] items, uint shop_id)
        is_customer()
        public payable returns(bool) {
                require(shop_id <= shop_count, "Shop doesn't exist");
        require(customer_details[get_customer_id[msg.sender]].cur_order == 0, "Already placed order");
        require(items.length * clothes_cost + delivery_fee == msg.value, "Insufficient amount");
        uint i;
        for (i = 0; i < items.length; i++) {
            require(item_exists(items[i], shop_id) == true, "Item doesn't exist");
        }

        order_count++;
        Order storage o = order_details[order_count];
        o.id = order_count;
        o.items = items;
        o.price = items.length * clothes_cost;
        o.status = OrderStatus.ordered;
        o.shop = shop_id;
        o.cust = get_customer_id[msg.sender];

        customer_details[get_customer_id[msg.sender]].cur_order = o.id;
        emit order_update(o.id, o.status);
        return true;
    
}

        function confirm_clothes_arrival()
        is_customer()
        has_ordered()
public returns (bool) {
            uint order_id = customer_details[get_customer_id[msg.sender]].cur_order;
            order_details[order_id].status = OrderStatus.delivered;
            customer_details[get_customer_id[msg.sender]].cur_order = 0;
            customer_details[get_customer_id[msg.sender]].last_order = order_id;
            emit order_update(order_id, OrderStatus.delivered);

            return true;
        }

        function withdraw_money()
        is_customer()
        has_ordered()
        public payable returns (bool) {
                uint order_id = customer_details[get_customer_id[msg.sender]].cur_order;
        require(now - order_details[order_id].time > time_limit, "Please wait a little longer");

        msg.sender.transfer(order_details[order_id].price + delivery_fee);

        return true;
}

        function rate_courier(uint rating)
        is_customer()
public returns (bool) {
            require(customer_details[get_customer_id[msg.sender]].last_order != 0, "You haven't ordered");
            require(rating >= 0 && rating <= 5, "Invalid rating");

            uint order_id = customer_details[get_customer_id[msg.sender]].last_order;
            order_details[order_id].del_rating = rating;
            // NEED TO ADD UPDATION OF AVERAGE RATING
            return true;
        }

        function rate_clothes(uint rating)
        is_customer()
public returns (bool) {
            require(customer_details[get_customer_id[msg.sender]].last_order != 0, "You haven't ordered");
            require(rating >= 0 && rating <= 5, "Invalid rating");

            uint order_id = customer_details[get_customer_id[msg.sender]].last_order;
            order_details[order_id].shop_rating = rating;
            // NEED TO ADD UPDATION OF AVERAGE RATING
            return true;
        }

        function get_status()
        is_customer()
        has_ordered()
        public view returns (OrderStatus) {
                uint order_id = customer_details[get_customer_id[msg.sender]].cur_order;
        return order_details[order_id].status;
}

        /* ---------------COURIER---------------- */

        function accept_delivery(uint order_id)
        is_courier()
        public payable returns (bool) {
                uint courier_id = get_courier_id[msg.sender];
        require(courier_details[courier_id].cur_order == 0, "Already delivering another order");
        require(order_details[order_id].status == OrderStatus.accepted, "Already claimed");

        emit order_update(order_id, OrderStatus.courier_found);
        order_details[order_id].status = OrderStatus.courier_found;
        order_details[order_id].del = get_courier_id[msg.sender];
        courier_details[courier_id].cur_order = order_id;

        return true;
}

        function collect_clothes(uint order_id)
        is_courier()
public returns (bool) {
            uint courier_id = get_courier_id[msg.sender];
            require(courier_details[courier_id].cur_order == order_id, "Not your order");
            require(order_details[order_id].status == OrderStatus.prepared, "Clothes not yet packed");

            emit order_update(order_id, OrderStatus.picked);
            order_details[order_id].status = OrderStatus.picked;

            return true;

        }

        function deliver_clothes(uint order_id)
        is_courier()
public returns (bool) {
            uint courier_id = get_courier_id[msg.sender];
            require(courier_details[courier_id].cur_order == order_id, "Not your order");
            require(order_details[order_id].status == OrderStatus.picked, "Your order not yet picked");


            return true;

        }

        function collect_delivery_fee(uint order_id)
        is_courier()
public returns (bool) {
            uint courier_id = get_courier_id[msg.sender];
            require(courier_details[courier_id].cur_order == order_id, "Not your order");
            require(order_details[order_id].status == OrderStatus.delivered, "Package not yet delivered");

            msg.sender.transfer(delivery_fee);
            courier_details[courier_id].cur_order = 0;

            return true;
        }

        /* ---------------SHOP------------- */

        function accept_order(uint order_id)
        is_shop
public returns (bool) {
            uint shop_id = get_shop_id[msg.sender];
            require(order_details[order_id].shop == shop_id, "Not your order");
            require(order_details[order_id].status == OrderStatus.ordered, "Already accepted this order");

            emit order_update(order_id, OrderStatus.accepted);
            order_details[order_id].status = OrderStatus.accepted;

            return true;
        }

        function pack_clothes(uint order_id)
        is_shop()
public returns (bool) {
            uint shop_id = get_shop_id[msg.sender];
            require(order_details[order_id].shop == shop_id, "Not your order");
            require(order_details[order_id].status == OrderStatus.courier_found, "Courier not found");

            emit order_update(order_id, OrderStatus.prepared);
            order_details[order_id].status = OrderStatus.prepared;

            return true;
        }

        function collect_clothes_fee(uint order_id)
        is_shop()
public returns (bool) {
            uint shop_id = get_shop_id[msg.sender];
            require(order_details[order_id].shop == shop_id, "Not your order");
            require(order_details[order_id].status == OrderStatus.picked, "Courier has not picked it yet");

            msg.sender.transfer(order_details[order_id].price);
            return true;
        }

    }
