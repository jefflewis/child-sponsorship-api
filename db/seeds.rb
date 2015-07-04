jeff = User.create!( name:                  'Jeff Lewis',
                     email:                 'lewisj88@mac.com',
                     password:               'foobar',
                     access:                 10,
                     password_confirmation:  'foobar',
                     activated:              true,
                     activated_at:           Time.now.getutc )

test_user = User.create!(name:                  'Test User',
                         email:                 'mail@jeffreylewis.me',
                         password:               'foobar',
                         access:                 1,
                         password_confirmation:  'foobar',
                         activated:              true,
                         activated_at:           Time.now.getutc )

harriet = Child.create!(name: "Harriet",
                        description: "Young Girl",
                        birthdate: Date.parse('20010-07-13'),
                        gender: "male",
                        user_id: 1 )

jonah = Child.create!(name: "Jonah",
                      description: "Young Boy",
                      birthdate: Date.parse('2008-03-03'),
                      gender: "male",
                      user_id: 1 )

samantha = Child.create!( name: "Samantha",
                          description: "Younger Girl",
                          birthdate: Date.parse('2003-06-22'),
                          gender: "female",
                          user_id: 2 )

peter = Child.create!(name: "Peter",
                      description: "Younger Boy",
                      birthdate: Date.parse('2005-02-07'),
                      gender: "male" )

photo1 = ChildPhoto.create!( url: "http://sci8.com/wp-content/uploads/2014/10/test-all-the-things.jpg",
                              caption: "test all the things",
                              child_id:1 )
                              
photo2 = ChildPhoto.create!( url: "https://dirghakala.files.wordpress.com/2012/06/puppy1.jpg",
                              caption: "pups are the best",
                              child_id: 1)
                              

photo3 = ChildPhoto.create!( url: "http://sci8.com/wp-content/uploads/2014/10/test-all-the-things.jpg",
                              caption: "test all the things",
                              child_id:2 )

photo4 = ChildPhoto.create!( url: "https://dirghakala.files.wordpress.com/2012/06/puppy1.jpg",
                              caption: "pups are the best",
                              child_id: 2)
                              
photo5 = ChildPhoto.create!( url: "http://sci8.com/wp-content/uploads/2014/10/test-all-the-things.jpg",
                              caption: "test all the things",
                              child_id:3 )

photo6 = ChildPhoto.create!( url: "https://dirghakala.files.wordpress.com/2012/06/puppy1.jpg",
                              caption: "pups are the best",
                              child_id: 4)