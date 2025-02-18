Vue
    .createApp({
        data() {
            return list_data;
        },
        computed: {
            filtered_users() {
                const selected_roles = this.roles.filter( role => role.selected ).map( role => role.name );
                if ( selected_roles.length == 0 ) return this.users;
                return this.users.filter( user => user.roles.some( role => selected_roles.includes(role) ) );
            },
        },
    })
    .mount('#user_list');
