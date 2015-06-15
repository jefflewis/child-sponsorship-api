jeff = User.create!( name:                  'jeff',
                     email:                 'test@test.com',
                     password:               'foobar',
                     access:                 10,
                     password_confirmation:  'foobar',
                     activated:              true,
                     activated_at:           Time.now.getutc )

user2 = User.create!(name:                  'user2',
                     email:                 'test2@test.com',
                     password:               'foobar',
                     access:                 1,
                     password_confirmation:  'foobar',
                     activated:              true,
                     activated_at:           Time.now.getutc )